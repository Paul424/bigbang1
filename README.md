# bigbang1

Just a test / demo setup to run bigbang on KinD.

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

## Config

Increase the max open file limit
```
# /etc/systemd/system.conf
DefaultLimitNOFILE=524288
```

Increase max file watches
```
# Append to /etc/sysctl.d/99-sysctl.conf and reload using sysctl -p
fs.inotify.max_queued_events=616384
fs.inotify.max_user_instances=512
fs.inotify.max_user_watches=786432
```

Override for WSL2 confs
```
# C:\Users\<your-username>\.wslconfig
[wsl2]
kernelCommandLine = cgroup_no_v1=all
memory=24GB
```

## Account

Access to the git versioned scripts (of this repo)
- [github account](https://github.com/)

Access to the upstream charts and images
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

Add the aliases to your /etc/hosts as fake DNS service
```
172.18.0.5      keycloak.dev.bigbang.mil
172.18.0.6      kiali.dev.bigbang.mil
172.18.0.6      grafana.dev.bigbang.mil
172.18.0.6      prometheus.dev.bigbang.mil
```

And test access from the terminal using:
```
curl -I https://kiali.dev.bigbang.mil/kiali/
HTTP/2 200 
```

## Load realm into keycloak

We run a keycloak instance within the same / single cluster which needs a realm setup with clients and users.

Open the [kaycloak UI](https://keycloak.dev.bigbang.mil/auth/admin/master/console/#/master/realm-settings) and import the realm from ```./data/realm.json``` this includes the realm + clients + users.

# Access

## WSL2 / Tunnel

The services are exposed using type: LoadBalancer to the docker network which in case of wsl2 is not visible from the host (Windows) machine. This can be solved by running a socks5 proxy icw a browser plugin to use the local proxy as a tunnel.

1. Within wsl install / configure and run a SSH server
2. On the Windows box install putty and puttygen
3. Using puttygen create a new keypair, save the private key to a .ppk file (for putty to use) and append the public key to the ~/.ssh/authorized_keys in the wsl box.
4. Create a new putty session with:
    - Server is just the ip4 address of the eth0 adapter
    - Port is the default tcp/22
    - On connection - data set Auto-login username to your username
    - On connection - SSH - Auth - Credentials point the private key for authentication to the .ppk file.
    - On connection - SSH - Tunnels add a dynamic port forwarding on local port tcp/12345
5. Save and run this new session and confirm you can login.
6. Install foxyproxy on Chrome and add a proxy named wsl2 with:
    - type: SOCKS5
    - hostname: localhost
    - port: 12345
    - Add a proxy-by-pattern to include any request matching ```https://*.dev.bigbang.mil/```
7. Open a new tab and access one of the apps, for instance: ```https://prometheus.dev.bigbang.mil/``` and make sure foxyproxy is active for this tab.
8. In C:\Windows\System32\drivers\etc\hosts create (fake) DNS mapping for instance:
```
172.18.0.6      kiali.dev.bigbang.mil
172.18.0.6      grafana.dev.bigbang.mil
172.18.0.6      prometheus.dev.bigbang.mil
172.18.0.7      keycloak.dev.bigbang.mil
```

## Credentials (defaults)

https://docs-bigbang.dso.mil/latest/docs/configuration/default-credentials/#packages-with-no-built-in-authentication

## Links

1. [Keycloak](https://keycloak.dev.bigbang.mil/auth/admin)
2. 

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
