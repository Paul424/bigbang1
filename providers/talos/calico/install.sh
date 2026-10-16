#!/bin/bash
set -euxo pipefail

BASE=$(dirname $(realpath $0))

WAIT_TIMEOUT=300
NAMESPACE=calico-system

kubectl apply --server-side --kustomize $BASE

kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/calico-kube-controllers"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/calico-typha"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/calico-webhooks"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/goldmane"
kubectl wait --for=condition=available --timeout "${WAIT_TIMEOUT}s" -n $NAMESPACE "deployment/whisker"

kubectl apply --server-side --kustomize $BASE/installation
