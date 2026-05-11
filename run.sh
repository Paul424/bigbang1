#!/bin/bash
set -x

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind|up_kind_lb|down_kind|up_bigbang|template_bigbang|template_component} [naam]"
    exit 1
fi

BASE=$(dirname $(realpath $0))
COMMAND="$1"
shift

SOPS_KEY_NAME="dev.bigbang.mil"

function up_kind {
    CLUSTER_NAME=${1}
    kind create cluster --config=kind.yaml --name $CLUSTER_NAME --verbosity 2
    kubectl config view --minify=false --raw=true > ~/.kube/${CLUSTER_NAME}-dev-quickstart-config
}

function down_kind {
    CLUSTER_NAME=${1}
    kind delete cluster --name $CLUSTER_NAME
}

function up_kind_lb {
    # Install cloud-provider-kind from https://github.com/kubernetes-sigs/cloud-provider-kind/releases
    if ! [ -x "$(command -v cloud-provider-kind)" ]; then
        echo 'Error: cloud-provider-kind is not installed.' >&2
        exit 1
    fi
    cloud-provider-kind > ./log/cloud-provider-kind.log 2>&1
}

function generate_sops_keys {
    KEY_COMMENT="flux secrets"

    gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: ${KEY_COMMENT}
Name-Real: ${SOPS_KEY_NAME}
EOF

FP=$(gpg --fingerprint --with-colons "$SOPS_KEY_NAME" | awk -F: '/^fpr:/ { print $10; exit }')
if [ -z "$FP" ]; then
    echo "Fingerprint not found"
    exit 1
else
    echo "Fingerprint: $FP"
fi

# Set the finger-print in the .sops.yaml config.
sed -i "s/pgp: .*/pgp: ${FP}/" $BASE/.sops.yaml

}

function bootstrap {
    CLUSTER_NAME=${1}
    export REPO1_LOCATION=$BASE/upstream

    # Create the namespace for initial secrets
    kubectl create namespace bigbang --dry-run=client -o yaml | kubectl apply -f -

    # Export the SOPS key to the cluster
    gpg --export-secret-key --armor "${SOPS_KEY_NAME}" | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey.asc=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -

    # Git (private) repo credentials
    kubectl create secret generic private-git -n bigbang \
        --from-literal=username=$REGISTRY_UPSTREAM_USERNAME \
        --from-literal=password=$REGISTRY_UPSTREAM_PAT \
        --dry-run=client -o yaml | kubectl apply -f -

    # Deploy flux
    git clone https://repo1.dso.mil/big-bang/bigbang.git $REPO1_LOCATION/bigbang
    $REPO1_LOCATION/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_PASSWORD

    # The top level reconciler
    kubectl apply -f environments/dev/bigbang.yaml
}







function up_bigbang {
    CLUSTER_NAME=${1}  # To map the kind context
    export REPO1_LOCATION=$BASE/upstream
    bash ./quickstart.sh --host $CLUSTER_NAME --deploy -- \
        --set helmRepositories[0].username=${REGISTRY_UPSTREAM_USERNAME} \
        --set helmRepositories[0].password=${REGISTRY_UPSTREAM_PAT} \
        --set helmRepositories[1].username=${REGISTRY_UPSTREAM_USERNAME} \
        --set helmRepositories[1].password=${REGISTRY_UPSTREAM_PAT} \
        -f $BASE/bigbang.yaml
}

function up_hacks {
    CLUSTER_NAME=${1}
    kubectl apply -f $BASE/manifests/dev-clusterrolebinding.yaml
}

function template_bigbang {
    OUTPUT=${1}
    echo "Templating bigbang to $OUTPUT"
    rm -rf ./$OUTPUT
    helm template ./upstream/big-bang/bigbang/chart \
        -n bigbang \
        --create-namespace \
        --set registryCredentials.username=${REGISTRY1_USERNAME} \
        --set registryCredentials.password=${REGISTRY1_TOKEN} \
        --set helmRepositories[0].username=${REGISTRY_UPSTREAM_USERNAME} \
        --set helmRepositories[0].password=${REGISTRY_UPSTREAM_PAT} \
        --set helmRepositories[1].username=${REGISTRY_UPSTREAM_USERNAME} \
        --set helmRepositories[1].password=${REGISTRY_UPSTREAM_PAT} \
        -f $BASE/bigbang.yaml \
        -f ./upstream/big-bang/bigbang/chart/ingress-certs.yaml \
        --output-dir ./$OUTPUT
        # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/dev-sso-values.yaml
        # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/policy-overrides-k3d.yaml
}

function template_component_extract_values {
    local OUTPUT=${1}
    local COMPONENT=${2}
    echo "Extracting values for $COMPONENT from $OUTPUT"
    mkdir -p ./$OUTPUT/$COMPONENT
    # equivalent of:
    # kubectl get secret -n bigbang bigbang-kiali-values -o json | jq -r '.data.defaults' | base64 -d
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.common' > ./$OUTPUT/$COMPONENT/values-common.yaml
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.defaults' > ./$OUTPUT/$COMPONENT/values-defaults.yaml
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.overlays' > ./$OUTPUT/$COMPONENT/values-overlays.yaml
    # wrapper exceptions
    cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData."values.yaml"' > ./$OUTPUT/$COMPONENT/values.yaml
}

function template_wrapper_component_extract_values {
    local OUTPUT=${1}
    local COMPONENT=${2}
    echo "Extracting values for $COMPONENT (wrapper) from $OUTPUT"
    mkdir -p ./$OUTPUT/wrapper
    cat ./$OUTPUT/bigbang/templates/wrapper/values.yaml | yq e '.stringData."values.yaml"' > ./$OUTPUT/wrapper/values.yaml
    mkdir -p ./$OUTPUT/$COMPONENT
    cat ./$OUTPUT/wrapper/values.yaml | yq e '.package.values' > ./$OUTPUT/$COMPONENT/values.yaml
}

function checkout_component_repo {
    local COMPONENT=${1}
    local GIT_REMOTE=${2}
    local ARG_VERSION=${3}
    local REPO_PATH=./upstream/${COMPONENT}
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
    local OUTPUT=${1}
    local COMPONENT=${2}

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
            NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
            checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION
            ;;

        *)
            # Extract remote from the GitRepository resource
            GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
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
        -n $NAMESPACE \
        --output-dir ./$OUTPUT
}

function template_wrapper_component {
    local OUTPUT=${1}
    local COMPONENT=${2}

    # Umbrella chart to generate the values (and gitops confs)
    template_bigbang $OUTPUT

    # Extract the values from gitops resources
    template_wrapper_component_extract_values $OUTPUT $COMPONENT

    # Setup clone for the wrapper upstream (from GitRepository resource)
    # Extract remote from the GitRepository resource
    GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
    ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
    NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/wrapper/helmrelease.yaml)
    checkout_component_repo wrapper $GIT_REMOTE $ARG_VERSION
    
    # Template out for the wrapper
    echo "Templating wrapper ($COMPONENT) to $OUTPUT/wrapper"
    # rm -rf ./$OUTPUT/$COMPONENT
    helm template ./upstream/wrapper/chart \
        -f ./$OUTPUT/wrapper/values.yaml \
        -n $NAMESPACE \
        --output-dir ./$OUTPUT

    # Setup clone for the component upstream (from GitRepository resource)
    # todo: Needs support for git/helmrepo upstream :-(

    # Template out for the function
    # todo...
}

function install_component {
    local OUTPUT=${1}
    local COMPONENT=${2}

    # Umbrella chart to generate the values (and gitops confs)
    template_bigbang $OUTPUT

    # Extract the values from gitops resources
    template_component_extract_values $OUTPUT $COMPONENT

    # Setup clone for the upstream (from GitRepository resource)
    case "$COMPONENT" in
        *)
            # Extract remote from the GitRepository resource
            GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
            NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
            NAME=$(yq e '.metadata.name' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
            checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION
            ;;
    esac
    
    # Template out for the function
    echo "Apply $COMPONENT to $OUTPUT/$COMPONENT"
    # rm -rf ./$OUTPUT/$COMPONENT
    helm upgrade --install $NAME ./upstream/$COMPONENT/chart \
        -f ./$OUTPUT/$COMPONENT/values-common.yaml \
        -f ./$OUTPUT/$COMPONENT/values-defaults.yaml \
        -f ./$OUTPUT/$COMPONENT/values-overlays.yaml \
        -n $NAMESPACE \
        --debug
}

function up_debug {
    # Just manipulate the yaml as you see fit...
    kubectl apply -f $BASE/manifests/netshoot.yaml
}

function up_kc_config {
    # Create (update) a kube config context using OIDC
    #
    # Example: 
    #   kubectl --context barney get pods -A
    #   [OK]
    #
    #   kubectl --context barney delete pod -n kiali kiali-7ccd646bb-ltgxs
    #   Error from server (Forbidden): pods "kiali" is forbidden: User "https://keycloak.dev.bigbang.mil/auth/realms/me-yoda#barney" cannot delete resource "pods" in API group "" in the namespace "kiali"
    #
    #   kubectl --context fred delete pod -n kiali kiali-7ccd646bb-ltgxs
    #   pod "kiali-7ccd646bb-ltgxs" deleted from kiali namespace
    local USERNAME=${1};
    local CLUSTER_NAME=${2};
    local CLIENT_ID=kubernetes
    local ISSUER=https://keycloak.dev.bigbang.mil/auth/realms/me-yoda
    local ENDPOINT=$ISSUER/protocol/openid-connect/token
    local ID_TOKEN=$(curl -k -X POST $ENDPOINT \
        -d grant_type=password \
        -d client_id=$CLIENT_ID \
        -d username=$USERNAME \
        -d password=$USERNAME \
        -d scope=openid \
        -d response_type=id_token | jq -r '.id_token')
    local REFRESH_TOKEN=$(curl -k -X POST $ENDPOINT \
        -d grant_type=password \
        -d client_id=$CLIENT_ID \
        -d username=$USERNAME \
        -d password=$USERNAME \
        -d scope=openid \
        -d response_type=id_token | jq -r '.refresh_token')
    local CA_DATA=$(kubectl get secret -n keycloak keycloak-keycloak-tlscert -o json | jq -r '.data."tls.crt"')
    kubectl config set-credentials $USERNAME \
        --auth-provider=oidc \
        --auth-provider-arg=client-id=$CLIENT_ID \
        --auth-provider-arg=idp-issuer-url=$ISSUER \
        --auth-provider-arg=id-token=$ID_TOKEN \
        --auth-provider-arg=refresh-token=$REFRESH_TOKEN \
        --auth-provider-arg=idp-certificate-authority-data=$CA_DATA
    kubectl config set-context $USERNAME --cluster=$CLUSTER_NAME --user=$USERNAME
}

case "$COMMAND" in
    up_kind)
        CLUSTER_NAME=${1:-bb1};
        shift
        up_kind $CLUSTER_NAME
        ;;
    
    down_kind)
        CLUSTER_NAME=${1:-bb1};
        shift
        down_kind $CLUSTER_NAME
        ;;

    up_kind_lb)
        up_kind_lb
        ;;
    
    generate_sops_keys)
        generate_sops_keys
        ;;

    bootstrap)
        CLUSTER_NAME=${1:-bb1};
        shift
        bootstrap $CLUSTER_NAME
        ;;

    up_bigbang)
        CLUSTER_NAME=${1:-bb1};
        shift
        up_bigbang $CLUSTER_NAME
        ;;
    
    up_hacks)
    CLUSTER_NAME=${1:-bb1};
        shift
        up_hacks $CLUSTER_NAME
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

    template_wrapper_component)
        COMPONENT=${1:-openldap};
        OUTPUT=${2:-out};
        shift
        template_wrapper_component $OUTPUT $COMPONENT
        ;;

    install_component)
        COMPONENT=${1:-kiali};
        OUTPUT=${2:-out};
        shift
        install_component $OUTPUT $COMPONENT
        ;;

    debug)
        up_debug
        ;;

    up_kc_config)
        USERNAME=${1:-barney};
        CLUSTER_NAME=${2:-bb1};
        shift
        up_kc_config $USERNAME $CLUSTER_NAME
        ;;

    *)
        echo "Invalid argument"
        echo "Usage: $0 {up_kind} [naam]"
        exit 1
        ;;
esac
