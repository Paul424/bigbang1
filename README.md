# bigbang1

Just a test / demo setup to run bigbang.

We are using the bigbang quickstart script mostly but since we want to use our own kind setup (and not k3d or aws) we wrap it in our own bash script (run.sh).

# Prerequisites

## Tools and environment
- go 
- kind 
- docker
- kubectl
- k9s
- kustomize
- helm
- flux cli
- pgp
- sops
- jq
- yq

## Account
- [github account](https://github.com/)
- [p1 registry account](https://registry1.dso.mil/)

# Setup

## Kind cluster

Spin a kind cluster:
```
bash ./run.sh up_kind
```

## Bootstrap bigbang


```
export REGISTRY1_USERNAME=<account-name-to-access-p1-registry>
export REGISTRY1_TOKEN=<p1-registry-cli-secret>
bash ./run.sh up_bigbang

```
