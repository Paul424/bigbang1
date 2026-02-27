#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind} [naam]"
    exit 1
fi

COMMAND="$1"
shift

function up_kind {
    NAME=${1}
    kind create cluster --config=kind.yaml --name $NAME
    # kind delete cluster
}


case "$COMMAND" in
    up_kind)
        NAME=${1:-bb1};
        shift
        up_kind $NAME
        ;;
    
    # stop)
    #     echo "Stoppen van service..."
    #     if [ -n "$NAAM" ]; then
    #         echo "Service naam: $NAAM"
    #     fi
    #     ;;
    
    # status)
    #     echo "Status opvragen..."
    #     if [ -n "$NAAM" ]; then
    #         echo "Service naam: $NAAM"
    #     fi
    #     ;;
    
    *)
        echo "Invalid argument"
        echo "Usage: $0 {kind} [naam]"
        exit 1
        ;;
esac
