#!/bin/bash
set -x

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind|up_bigbang} [naam]"
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

function up_bigbang {
    NAME=${1}
    export REPO1_LOCATION=$BASE/upstream
    bash ./quickstart.sh --host $NAME --deploy -- -f $BASE/bigbang.yaml
}

function template_bigbang {
    NAME=${1}
    rm -rf ./out
    helm template ./upstream/big-bang/bigbang/chart \
        -n bigbang --create-namespace \
        -f ./upstream/big-bang/bigbang/chart/ingress-certs.yaml \
        -f ./upstream/big-bang/bigbang/docs/reference/configs/example/dev-sso-values.yaml \
        -f ./upstream/big-bang/bigbang/docs/reference/configs/example/policy-overrides-k3d.yaml \
        -f $BASE/bigbang.yaml \
        --output-dir ./out
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
    
    up_bigbang)
        NAME=${1:-bb1};
        shift
        up_bigbang $NAME
        ;;

    template_bigbang)
        NAME=${1:-bb1};
        shift
        template_bigbang $NAME
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
