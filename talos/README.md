# Talos

First (ad-hoc) approach 

```
export CTL1_IP=192.168.50.102
export WRK1_IP=192.168.50.227
export WRK2_IP=192.168.50.92
export WRK3_IP=192.168.50.37

talosctl get disks --nodes $CTL1_IP --insecure
talosctl get disks --nodes $WRK1_IP --insecure
talosctl get disks --nodes $WRK2_IP --insecure
talosctl get disks --nodes $WRK3_IP --insecure

talosctl gen config \
  talos-proxmox-cluster \
  https://$CTL1_IP:6443 \
  --output-dir ./talos \
  --config-patch @./talos/config-patch.yaml \
  --config-patch-control-plane @./talos/config-patch-control-plane.yaml \
  --install-image factory.talos.dev/metal-installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.12.6 \
  --force

talosctl apply-config --nodes $CTL1_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl1.yaml --insecure
talosctl apply-config --nodes $WRK1_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk1.yaml --insecure
talosctl apply-config --nodes $WRK2_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk2.yaml --insecure
talosctl apply-config --nodes $WRK3_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk3.yaml --insecure

export TALOSCONFIG="./talos/talosconfig"
talosctl config endpoint $CTL1_IP
talosctl config node $CTL1_IP
talosctl bootstrap

# Fetch kube config and merge into default + a fixed location for bb to pickup
talosctl kubeconfig --merge
talosctl kubeconfig --merge ~/.kube/bb9-dev-quickstart-config

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
helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
helm install --create-namespace --namespace rook-ceph rook-ceph-cluster --set operatorNamespace=rook-ceph rook-release/rook-ceph-cluster

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
