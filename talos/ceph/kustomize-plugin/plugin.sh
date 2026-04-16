#!/bin/bash
cat - > ./talos/ceph/helm-output.yaml
kustomize build ./talos/ceph && rm ./talos/ceph/helm-output.yaml
