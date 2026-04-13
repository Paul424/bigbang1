# Talos

First (ad-hoc) approach 

```
HW:
  p1: i5(6vcpu)|256(nvme)|512(ssd)|32GB
    ctl1: 6vcpu|16GB(nvme)|4GB
    wrk1: 6vcpu|16GB(nvme)|480(ssd)|28GB
  p2: i5(6vcpu)|256(nvme)|512(ssd)|32GB
    ctl2: 6vcpu|16GB(nvme)|4GB
    wrk2: 6vcpu|16GB(nvme)|480(ssd)|28GB
  p3: i5(6vcpu)|256(nvme)|512(ssd)|8GB
    ctl3: 6vcpu|16GB(nvme)|4GB
    wrk3: 6vcpu|16GB(nvme)|480(ssd)|8GB

export CTL1_IP=192.168.50.173
export CTL2_IP=192.168.50.62
export CTL3_IP=192.168.50.56
export WRK1_IP=192.168.50.146
export WRK2_IP=192.168.50.114
export WRK3_IP=192.168.50.205

talosctl get disks --nodes $CTL1_IP --insecure
talosctl get disks --nodes $WRK1_IP --insecure

talosctl gen config \
  bb9 \
  https://$CTL1_IP:6443 \
  --output-dir ./talos \
  --config-patch @./talos/config-patch.yaml \
  --config-patch-control-plane @./talos/config-patch-control-plane.yaml \
  --install-image factory.talos.dev/metal-installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.12.6 \
  --force

talosctl apply-config --nodes $CTL1_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl1.yaml --insecure
talosctl apply-config --nodes $CTL2_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl2.yaml --insecure
talosctl apply-config --nodes $CTL3_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl3.yaml --insecure
talosctl apply-config --nodes $WRK1_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk1.yaml --insecure
talosctl apply-config --nodes $WRK2_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk2.yaml --insecure
talosctl apply-config --nodes $WRK3_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk3.yaml --insecure

export TALOSCONFIG="./talos/talosconfig"
talosctl config endpoint $CTL1_IP $CTL2_IP $CTL3_IP
talosctl config node $CTL1_IP $CTL2_IP $CTL3_IP
talosctl bootstrap --nodes $CTL1_IP

# Fetch kube config and merge into default + a fixed location for bb to pickup
talosctl kubeconfig --merge --nodes $CTL1_IP
talosctl kubeconfig --merge --nodes $CTL1_IP ~/.kube/bb9-dev-quickstart-config

# Install the CNI
helm repo add cilium https://helm.cilium.io/
helm repo update

helm install \
    cilium \
    cilium/cilium \
    --version 1.18.0 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=false \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup

# Rook / Ceph
helm repo add rook-release https://charts.rook.io/release
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
# Somehow upgrade runs into conflicts; while template-out + apply did work!?
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph-cluster --values ./talos/rook-ceph.yaml rook-release/rook-ceph-cluster --debug
helm template --namespace rook-ceph rook-ceph-cluster --values ./talos/rook-ceph.yaml rook-release/rook-ceph-cluster --debug --output-dir ./debug/out.ceph-cluster

# Metallb
helm repo add metallb https://metallb.github.io/metallb
helm repo update

# Install MetalLB
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace
kubectl label namespace metallb-system pod-security.kubernetes.io/enforce=privileged
kubectl apply -f ./talos/metallb-l2-config.yaml
kubectl get ipaddresspool -n metallb-system



# Scratchpad
kubectl port-forward -n rook-ceph svc/rook-ceph-mgr-dashboard 8443:8443

```
