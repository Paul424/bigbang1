#!/bin/bash
cat - > ./talos/bind9/helm-output.yaml
kustomize build ./talos/bind9 && rm ./talos/bind9/helm-output.yaml
