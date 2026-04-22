# Bigbang1

Just a test / demo setup to run bigbang on KinD and Talos (on Proxmox).

We are using the bigbang quickstart script mostly but since we want to use our own kind and Talos setup (and not k3d or aws) we wrap it in our own bash script (run.sh).

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

## Accounts

Access to the git versioned scripts (of this repo)
- [github account](https://github.com/)

Access to the upstream charts and images
- [p1 registry account](https://registry1.dso.mil/)

# Infrastructure (provider)

## Kind cluster
When using a kind cluster, see [kind / wsl guidelines](./kind/README.md)

## Talos (on Proxmox) cluster
When using Talos, see [Talos guidelines](./talos/README.md)

# Bootstrap bigbang

Once the infrastructure is in place (meaning you have a container platform running on either kind or talos /w a working .kube/config and also there is support for DNS, storage and load-balancing), then you can proceed to bootstrap bigbang.

## GitOps

Bootstrap bigbang (flux.io and configured HelmReleases)
```
export REGISTRY1_USERNAME=<account-name-to-access-p1-registry>
export REGISTRY1_TOKEN=<p1-registry-cli-secret>
export REGISTRY_UPSTREAM_USERNAME=<account-name-to-access-your-git-repo>
export REGISTRY_UPSTREAM_PAT=<token-to-authenticate-to-git>
bash ./run.sh up_bigbang <CLUSTER-NAME>
```

## Apply Hacks

This is to overcome issue's with the upstream
```
bash ./run.sh up_hacks
```

## Load realm into keycloak

We run a keycloak instance within the same / single cluster which needs a realm setup with clients and users.

Open the [kaycloak UI](https://keycloak.dev.bigbang.mil/auth/admin/master/console/#/master/realm-settings) and import the realm from ```./data/realm.json``` this includes the realm + clients + users.

## Setup kubectl context using OIDC

By default KinD and Talos create a kube config with just signed certificates giving you admin access to the api-server. Since the api-server is configured with OIDC (backed by keycloak) we can also add a context per User defined in keycloak:

```
bash ./run.sh up_kc_config <barney|betty|fred|wilma> <CLUSTER-NAME=kind-bb9|bb9>

kubectl get nodes --context barney
Error from server (Forbidden): nodes is forbidden: User "barney" cannot list resource "nodes" in API group "" at the cluster scope

kubectl get nodes --context fred
NAME         STATUS   ROLES           AGE   VERSION
talos-ctl1   Ready    control-plane   24h   v1.35.2
talos-ctl2   Ready    control-plane   24h   v1.35.2
talos-ctl3   Ready    control-plane   24h   v1.35.2
talos-wrk1   Ready    <none>          24h   v1.35.2
talos-wrk2   Ready    <none>          24h   v1.35.2
talos-wrk3   Ready    <none>          24h   v1.35.2
```

# Access to Apps

## Network access to endpoints

When using a kind cluster, see [kind / wsl access guidelines](./kind/README.md#network-access)

When using Talos, see [Talos access guidelines](./talos/README.md#network-access)

## Credentials

Apps are using following [default credentials](https://docs-bigbang.dso.mil/latest/docs/configuration/default-credentials/#packages-with-no-built-in-authentication)

SSO is preconfigured using Keycloak with following users:

| Username | Password | AuthZ |
| --- | ----------- | --- |
| fred | fred | platform administrators (kube admins) |
| wilma | wilma | infra-structure operator |
| barney | barney | application operators |
| betty | betty | platform administrators |
| pebbles | pebbles | application operators |

> [!NOTE]
> When logging out in an app, the OIDC session still exists and attemts to login using SSO will reuse the existing session. To switch users, [login to keycloak](https://keycloak.dev.bigbang.mil/auth/admin/master/console/#/me-yoda/sessions) to remove the session manually.

## App Links

1. [Keycloak](https://keycloak.dev.bigbang.mil/auth/admin)
2. [Harbor](https://harbor.dev.bigbang.mil/)
3. [Prometheus](https://prometheus.dev.bigbang.mil/)
4. [AlertManager](https://alertmanager.dev.bigbang.mil/)
5. [Kiali](https://kiali.dev.bigbang.mil/kiali/)
6. [Grafana](https://grafana.dev.bigbang.mil/)
7. [Headlamp](https://headlamp.dev.bigbang.mil/)
8. [Twistlock](https://twistlock.dev.bigbang.mil/)
9. [Neuvector](https://neuvector.dev.bigbang.mil/)

Talos specific:

1. [Ceph](https://ceph.dev.bigbang.mil:8443/)


# Authentication and Authorization

We use an on-cluster Keycloak to address (on-cluster) clients (services) and roles (which map to RBAC). The users are sync'ed from an upstream openldap instance with 5 fixed users mapped to personas in the ldap registry.

# Debugging

## Template out from main chart

```
bash ./run.sh template_bigbang <OUTPUT>
```

## Template out a component

```
# build-in component
bash ./run.sh template_component <COMPONENT> <OUTPUT>

# package (extension)
bash ./run.sh template_wrapper_component openldap out.openldap.a
```

# Extras

Cluster API demo using local provisioner

```
export CLUSTER_TOPOLOGY=true

# Initialize infrastructure using (local) docker engine
clusterctl init --infrastructure docker

# Apply the (demo) cluster
clusterctl generate cluster capi-quickstart \
  --flavor development \
  --kubernetes-version v1.35.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > ./debug/capi-quickstart.yaml
kubectl apply -f ./debug/capi-quickstart.yaml

# Fetch and merge the kube config
kind get kubeconfig --name capi-quickstart > ./debug/capi-quickstart.kubeconfig
export KUBECONFIG=~/.kube/config:./debug/capi-quickstart.kubeconfig
cp ~/.kube/config ~/.kube/config-$(date +"%Y%m%d%H%M%S")
kubectl config view --flatten > ~/.kube/config-merged
cp ~/.kube/config-merged ~/.kube/config
rm -rf ~/.kube/config-merged

# Install a CNI
kubectl --kubeconfig=./debug/capi-quickstart.kubeconfig \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

# Hacks & Issues

## Missing AuthorizationPolicies

When istio.hardened is set to false then the components are missing their AuthorizationPolicies because istio itself does have an AuthorizationPolicy (default-deny-all) in its root namespace; making it the default for any workload in the mesh.

```
# Allow keycloak to reach its own database
./manifests/debug-authorization-policy-keycloak-allow-all.yaml

# Allow authservice to access keycloak
./manifests/debug-authorization-policy-authservice-allow-all.yaml

# Allow metrics-server to serve the v1beta1.metrics.k8s.io API
./manifests/debug-authorization-policy-metrics-server-allow-all.yaml

# Allow access to Grafana
./manifests/debug-authorization-policy-monitoring-allow-all.yaml
```

## Upstream issue's

- https://repo1.dso.mil/big-bang/product/packages/headlamp/-/issues/81

## Access issue's (TLS connection aborted etc...)

Possible causes:
1. Tunnel down; check putty
2. Load balancer IP's have changed; check the ingress services for their external addresses and match the /etc/hosts
3. Istio workload certificates expired; check using ```istioctl proxy-config secret <workload>```; easiest for renewal is to just kill the pod.
4. Authservice not responding as it should
5. SSO (keycloak) down

## Expired workload certificates

Workload certificates are known to NOT renew when the whole cluster is at sleep (running on a laptop, going into sleep mode...). A quick fix is to just kill all the envoy proxies and have k8s deal with it, this should trigger renewal.

```
istioctl proxy-config secret -n kiali  kiali-66d5969cbb-9hlr9
RESOURCE NAME     TYPE           STATUS     VALID CERT     SERIAL NUMBER                        NOT AFTER                NOT BEFORE
default           Cert Chain     ACTIVE     false          05a5a5704d098b3b5ed004f3c55c79f0     2026-03-20T12:10:11Z     2026-03-18T12:08:11Z
ROOTCA            CA             ACTIVE     true           ad3489a60eda98d657ac38809b6ada85     2036-03-15T12:06:13Z     2026-03-18T12:06:13Z
```

Fix:
```
sudo pkill envoy
```
