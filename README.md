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

## Conf

Increase the max open file limit
```
# /etc/systemd/system.conf
DefaultLimitNOFILE=524288
```

Increase max file watches
```
# Append to /etc/sysctl.d/99-sysctl.conf
fs.inotify.max_queued_events=616384
fs.inotify.max_user_instances=512
fs.inotify.max_user_watches=786432
# Reload met sysctl -p
```

Override for WSL2 confs
```
# C:\Users\<your-username>\.wslconfig
[wsl2]
kernelCommandLine = cgroup_no_v1=all
memory=24GB
```

## Account
- [github account](https://github.com/)
- [p1 registry account](https://registry1.dso.mil/)

# Setup

## Kind cluster

Setup the infrastructure (foundation using kind):
```
bash ./run.sh up_kind
```

## Bootstrap bigbang

Bootstrap bigbang (flux.io and configured HelmReleases)
```
export REGISTRY1_USERNAME=<account-name-to-access-p1-registry>
export REGISTRY1_TOKEN=<p1-registry-cli-secret>
bash ./run.sh up_bigbang
```

# Debug

## Template out from main chart

```
helm template ./upstream/big-bang/bigbang/chart -n bigbang --create-namespace -f ./upstream/big-bang/bigbang/chart/ingress-certs.yaml -f ./upstream/big-bang/bigbang/docs/reference/configs/example/dev-sso-values.yaml -f ./upstream/big-bang/bigbang/docs/reference/configs/example/policy-overrides-k3d.yaml --output-dir ./out
```