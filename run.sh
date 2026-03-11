#!/bin/bash
set -x

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind|up_kind_lb|down_kind|up_bigbang|template_bigbang|template_component} [naam]"
    exit 1
fi

BASE=$(dirname $(realpath $0))
COMMAND="$1"
shift

function up_kind {
    NAME=${1}
    kind create cluster --config=kind.yaml --name $NAME
    kubectl config view --minify=false --raw=true > ~/.kube/${NAME}-dev-quickstart-config
}

function down_kind {
    NAME=${1}
    kind delete cluster --name $NAME
}

function up_kind_lb {
    # Install cloud-provider-kind from https://github.com/kubernetes-sigs/cloud-provider-kind/releases
    if ! [ -x "$(command -v cloud-provider-kind)" ]; then
        echo 'Error: cloud-provider-kind is not installed.' >&2
        exit 1
    fi
    cloud-provider-kind > ./log/cloud-provider-kind.log 2>&1
}

function up_bigbang {
    NAME=${1}
    export REPO1_LOCATION=$BASE/upstream
    bash ./quickstart.sh --host $NAME --deploy -- -f $BASE/bigbang.yaml
}

function template_bigbang {
    OUTPUT=${1}
    echo "Templating bigbang to $OUTPUT"
    rm -rf ./$OUTPUT
    helm template ./upstream/big-bang/bigbang/chart \
        -n bigbang --create-namespace \
        -f $BASE/bigbang.yaml \
        -f ./upstream/big-bang/bigbang/chart/ingress-certs.yaml \
        --output-dir ./$OUTPUT
        # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/dev-sso-values.yaml
        # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/policy-overrides-k3d.yaml
}

function template_component_extract_values {
    OUTPUT=${1}
    COMPONENT=${2}
    echo "Extracting values for $COMPONENT from $OUTPUT"
    mkdir -p ./$OUTPUT/$COMPONENT
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.common' > ./$OUTPUT/$COMPONENT/values-common.yaml
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.defaults' > ./$OUTPUT/$COMPONENT/values-defaults.yaml
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.overlays' > ./$OUTPUT/$COMPONENT/values-overlays.yaml
}

function checkout_component_repo {
    COMPONENT=${1}
    GIT_REMOTE=${2}
    ARG_VERSION=${3}
    REPO_PATH=./upstream/${COMPONENT}
    if [[ ! -d ${REPO_PATH} ]]; then
        mkdir -p ${REPO_PATH}
        git clone $GIT_REMOTE ${REPO_PATH}
        pushd ${REPO_PATH}
    else
        pushd ${REPO_PATH}
    fi
    git fetch -a
    if [[ "${ARG_VERSION}" == "latest" ]]; then
        ARG_VERSION=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
    git checkout ${ARG_VERSION}
    popd
}

function template_component {
    OUTPUT=${1}
    COMPONENT=${2}

    # Umbrella chart to generate the values (and gitops confs)
    template_bigbang $OUTPUT

    # Extract the values from gitops resources
    template_component_extract_values $OUTPUT $COMPONENT

    # Setup clone for the upstream (from GitRepository resource)
    case "$COMPONENT" in
        kiali)
            # Extract remote from the GitRepository resource
            # GIT_REMOTE=https://repo1.dso.mil/big-bang/product/packages/kiali.git
            GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            # ARG_VERSION="2.22.0-bb.0"
            ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION
            ;;

        *)
            # Extract remote from the GitRepository resource
            GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION
            ;;
    esac
    
    # Template out for the function
    echo "Templating $COMPONENT to $OUTPUT/$COMPONENT"
    # rm -rf ./$OUTPUT/$COMPONENT
    helm template ./upstream/$COMPONENT/chart \
        -f ./$OUTPUT/$COMPONENT/values-common.yaml \
        -f ./$OUTPUT/$COMPONENT/values-defaults.yaml \
        -f ./$OUTPUT/$COMPONENT/values-overlays.yaml \
        --output-dir ./$OUTPUT
}


function up_debug {
    # Just manipulate the yaml as you see fit...
    kubectl apply -f $BASE/manifests/netshoot.yaml
}

case "$COMMAND" in
    up_kind)
        NAME=${1:-bb1};
        shift
        up_kind $NAME
        ;;
    
    down_kind)
        NAME=${1:-bb1};
        shift
        down_kind $NAME
        ;;

    up_kind_lb)
        up_kind_lb
        ;;
    
    up_bigbang)
        NAME=${1:-bb1};
        shift
        up_bigbang $NAME
        ;;

    template_bigbang)
        OUTPUT=${1:-out};
        shift
        template_bigbang $OUTPUT
        ;;

    template_component)
        COMPONENT=${1:-kiali};
        OUTPUT=${2:-out};
        shift
        template_component $OUTPUT $COMPONENT
        ;;

    debug)
        up_debug
        ;;

    *)
        echo "Invalid argument"
        echo "Usage: $0 {up_kind} [naam]"
        exit 1
        ;;
esac
