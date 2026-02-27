#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind|up_bigbang} [naam]"
    exit 1
fi

BASE=$(dirname $(realpath $0))
echo $BASE
COMMAND="$1"
shift

function up_kind {
    NAME=${1}
    # kind create cluster --config=kind.yaml --name $NAME
    kubectl config view --minify=false --raw=true > ~/.kube/${NAME}-dev-quickstart-config
    # kind delete cluster
}

function up_bigbang {
    NAME=${1}
    export REPO1_LOCATION=$BASE/upstream
    bash ./quickstart.sh --host $NAME --deploy
}


case "$COMMAND" in
    up_kind)
        NAME=${1:-bb1};
        shift
        up_kind $NAME
        ;;
    
    up_bigbang)
        NAME=${1:-bb1};
        shift
        up_bigbang $NAME
        ;;
    
    *)
        echo "Invalid argument"
        echo "Usage: $0 {up_kind} [naam]"
        exit 1
        ;;
esac
