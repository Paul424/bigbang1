# bigbang1

Just a test / demo setup to run bigbang.

We are using the bigbang quickstart script mostly but since we want to use our own kind setup (and not k3d or aws) we wrap it in our own bash script (run.sh).

# Prerequisites

## Tools and environment
- go 
- kind 
- cloud-provider-kind
- docker
- kubectl
- k9s
- kustomize
- helm
- flux cli
- istioctl
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

## Kind load balancer support

Run the cloud-provider-kind package to listen to services of type: LoadBalancer and expose the svc over a proxy / load-balancer running on the docker network.
```
bash ./run.sh up_kind_lb
```

Then find the IP's on which the LB is exposing:
```
kubectl get svc -n istio-gateway
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
passthrough-ingressgateway   LoadBalancer   10.96.10.33     172.18.0.5    15021:32735/TCP,80:32292/TCP,443:31843/TCP   143m
public-ingressgateway        LoadBalancer   10.96.140.121   172.18.0.6    15021:30373/TCP,80:31342/TCP,443:31088/TCP   160m
```

## Hostnames

Add the aliases to your /etc/hosts (C:\Windows\System32\drivers\etc\hosts on Windows) as fake DNS service
```
172.18.0.6      kiali.dev.bigbang.mil
```

## Bootstrap bigbang

Bootstrap bigbang (flux.io and configured HelmReleases)
```
export REGISTRY1_USERNAME=<account-name-to-access-p1-registry>
export REGISTRY1_TOKEN=<p1-registry-cli-secret>
bash ./run.sh up_bigbang
```

# Access

## Credentials (defaults)

https://docs-bigbang.dso.mil/latest/docs/configuration/default-credentials/#packages-with-no-built-in-authentication

## DNS

https://docs-bigbang.dso.mil/latest/docs/installation/environments/quick-start/#fix-dns-to-access-the-services-in-your-browser

# Debug

## Template out from main chart

```
bash ./run.sh template_bigbang <OUTPUT>
```

## Template out a component

```
bash ./run.sh template_component <COMPONENT> <OUTPUT>
```
