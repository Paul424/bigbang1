# Talos

Following is an (ad-hoc) manual to run bigbang on Proxmox/Talos

## Hardware setup
### Proxmox hosts
```
HW:
  p1: i5(6vcpu)|256(nvme)|512(ssd)|32GB
    ctl1: 6vcpu|16GB(nvme)|4GB
    wrk1: 6vcpu|16GB(nvme)|480(ssd)|26GB(26624)

  p2: i5(6vcpu)|256(nvme)|512(ssd)|20GB
    ctl2: 6vcpu|16GB(nvme)|4GB
    wrk2: 6vcpu|16GB(nvme)|480(ssd)|14GB(14336)

  p3: i5(6vcpu)|256(nvme)|512(ssd)|20GB
    ctl3: 6vcpu|16GB(nvme)|4GB
    wrk3: 6vcpu|16GB(nvme)|480(ssd)|14GB
```
### DHCP

Enable DHCP (excluding a cidr for load-balancing)
![DHCP1](./assets/dhcp-1.png)

Assign fixed addresses to the hosts and vm's
![DHCP2](./assets/dhcp-2.png)

## Proxmox

Shell into the proxmox node (one-by-one) using the gui and create the vm's

### Host P1
```
export BRIDGE=vmbr0
export VM_CTL1_NAME=bb9-ctl1
export VM_WRK1_NAME=bb9-wrk1
export VM_CTL1_ID=201
export VM_WRK1_ID=202

pvesm alloc local-lvm $VM_CTL1_ID vm-${VM_CTL1_ID}-disk-0 16G
pvesm alloc local-lvm $VM_WRK1_ID vm-${VM_WRK1_ID}-disk-0 16G
pvesm alloc data $VM_WRK1_ID vm-${VM_WRK1_ID}-disk-1 480G

qm create ${VM_CTL1_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_CTL1_NAME} \
  --net0 virtio=BC:24:11:F7:7E:51,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_CTL1_ID}-disk-0,size=16G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 4096 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm create ${VM_WRK1_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_WRK1_NAME} \
  --net0 virtio=BC:24:11:F7:7E:52,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_WRK1_ID}-disk-0,size=16G \
  --scsi1 data:vm-${VM_WRK1_ID}-disk-1,discard=on,size=480G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 26624 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm start ${VM_CTL1_ID}
qm start ${VM_WRK1_ID}
qm agent ${VM_CTL1_ID} network-get-interfaces
qm agent ${VM_WRK1_ID} network-get-interfaces
<...>
qm stop ${VM_CTL1_ID}
qm destroy ${VM_CTL1_ID}
qm stop ${VM_WRK1_ID}
qm destroy ${VM_WRK1_ID}
```

### Host P2
```
export BRIDGE=vmbr0
export VM_CTL2_NAME=bb9-ctl2
export VM_WRK2_NAME=bb9-wrk2
export VM_CTL2_ID=203
export VM_WRK2_ID=204

pvesm alloc local-lvm $VM_CTL2_ID vm-${VM_CTL2_ID}-disk-0 16G
pvesm alloc local-lvm $VM_WRK2_ID vm-${VM_WRK2_ID}-disk-0 16G
pvesm alloc data $VM_WRK2_ID vm-${VM_WRK2_ID}-disk-1 480G

qm create ${VM_CTL2_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_CTL2_NAME} \
  --net0 virtio=BC:24:11:F7:7E:53,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_CTL2_ID}-disk-0,size=16G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 4096 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm create ${VM_WRK2_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_WRK2_NAME} \
  --net0 virtio=BC:24:11:F7:7E:54,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_WRK2_ID}-disk-0,size=16G \
  --scsi1 data:vm-${VM_WRK2_ID}-disk-1,discard=on,size=480G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 14336 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm start ${VM_CTL2_ID}
qm start ${VM_WRK2_ID}
qm agent ${VM_CTL2_ID} network-get-interfaces
qm agent ${VM_WRK2_ID} network-get-interfaces
<...>
qm stop ${VM_CTL2_ID}
qm destroy ${VM_CTL2_ID}
qm stop ${VM_WRK2_ID}
qm destroy ${VM_WRK2_ID}
```

### Host P3
```
export BRIDGE=vmbr0
export VM_CTL3_NAME=bb9-ctl3
export VM_WRK3_NAME=bb9-wrk3
export VM_CTL3_ID=205
export VM_WRK3_ID=206

pvesm alloc local-lvm $VM_CTL3_ID vm-${VM_CTL3_ID}-disk-0 16G
pvesm alloc local-lvm $VM_WRK3_ID vm-${VM_WRK3_ID}-disk-0 16G
pvesm alloc data $VM_WRK3_ID vm-${VM_WRK3_ID}-disk-1 480G

qm create ${VM_CTL3_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_CTL3_NAME} \
  --net0 virtio=BC:24:11:F7:7E:55,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_CTL3_ID}-disk-0,size=16G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 4096 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm create ${VM_WRK3_ID} \
  --agent 1 \
  --ide2 local:iso/metal-amd64.iso,media=cdrom,size=308556K \
  --name ${VM_WRK3_NAME} \
  --net0 virtio=BC:24:11:F7:7E:56,bridge=${BRIDGE},firewall=1 \
  --scsi0 local-lvm:vm-${VM_WRK3_ID}-disk-0,size=16G \
  --scsi1 data:vm-${VM_WRK3_ID}-disk-1,discard=on,size=480G \
  --scsihw virtio-scsi-pci \
  --ostype l26 \
  --machine q35 \
  --memory 14336 \
  --onboot no \
  --sockets 1 \
  --cpu x86-64-v2-AES \
  --cores 6 \
  --boot "order=scsi0;ide2;net0" \
  --numa 0

qm start ${VM_CTL3_ID}
qm start ${VM_WRK3_ID}
qm agent ${VM_CTL3_ID} network-get-interfaces
qm agent ${VM_WRK3_ID} network-get-interfaces
<...>
qm stop ${VM_CTL3_ID}
qm destroy ${VM_CTL3_ID}
qm stop ${VM_WRK3_ID}
qm destroy ${VM_WRK3_ID}
```

## Bootstrap Talos (Kubernetes)

```
export CTL1_IP=192.168.50.180
export CTL2_IP=192.168.50.182
export CTL3_IP=192.168.50.184
export WRK1_IP=192.168.50.181
export WRK2_IP=192.168.50.183
export WRK3_IP=192.168.50.185

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

talosctl apply-config --nodes $CTL1_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl1.yaml
talosctl apply-config --nodes $CTL2_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl2.yaml
talosctl apply-config --nodes $CTL3_IP --file ./talos/controlplane.yaml --config-patch @./talos/config-patch-ctl3.yaml
talosctl apply-config --nodes $WRK1_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk1.yaml
talosctl apply-config --nodes $WRK2_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk2.yaml
talosctl apply-config --nodes $WRK3_IP --file ./talos/worker.yaml --config-patch @./talos/config-patch-wrk3.yaml

export TALOSCONFIG="./talos/talosconfig"
talosctl config endpoint $CTL1_IP $CTL2_IP $CTL3_IP
talosctl config node $CTL1_IP $CTL2_IP $CTL3_IP
talosctl bootstrap --nodes $CTL1_IP

# Fetch kube config and merge into default + a fixed location for bb to pickup
talosctl kubeconfig --merge --nodes $CTL1_IP
talosctl kubeconfig --merge --nodes $CTL1_IP ~/.kube/bb9-dev-quickstart-config
```

## Install CNI
```
# Install the CNI (Calico because we need nwpols /w ipBlock support for BB)
kubectl apply --kustomize ./talos/calico/
# Run twice for the crds
kubectl apply --kustomize ./talos/calico/
```

## Storage (Block, fs, s3) using Rook / Ceph
```
helm repo add rook-release https://charts.rook.io/release
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph --values ./talos/ceph/rook-ceph.yaml rook-release/rook-ceph
helm template --namespace rook-ceph rook-ceph --values ./talos/ceph/rook-ceph.yaml rook-release/rook-ceph --debug --output-dir ./debug/out.rook-ceph
helm plugin install ./talos/ceph/kustomize-ceph-plugin
kubectl label namespace rook-ceph pod-security.kubernetes.io/enforce=privileged
helm upgrade --install --create-namespace --namespace rook-ceph rook-ceph-cluster --values ./talos/ceph/rook-ceph-cluster.yaml rook-release/rook-ceph-cluster --post-renderer kustomization-ceph --debug
# helm template --namespace rook-ceph rook-ceph-cluster --values ./talos/ceph/rook-ceph-cluster.yaml rook-release/rook-ceph-cluster --post-renderer kustomization-ceph --debug --output-dir ./debug/out.rook-ceph-cluster
```

## DNS Server (bind9) for static .mil addresses
```
helm repo add unxwares https://helm.unxwares.studio
helm plugin install ./talos/bind9/kustomize-bind9-plugin
helm upgrade --install --create-namespace --namespace bind9 bind9 --values ./talos/bind9/values.yaml unxwares/bind9 --post-renderer kustomization-bind9 --debug
helm template --namespace bind9 bind9 --values ./talos/bind9/values.yaml unxwares/bind9 --post-renderer kustomization-bind9 --debug --output-dir ./debug/out.bind9

```

## Load balancer using Metallb
```
helm repo add metallb https://metallb.github.io/metallb
helm repo update

# Install MetalLB
helm install metallb metallb/metallb \
  --namespace metallb-system \
  --create-namespace
kubectl label namespace metallb-system pod-security.kubernetes.io/enforce=privileged
kubectl apply -f ./talos/metallb/metallb-l2-config.yaml
kubectl get ipaddresspool -n metallb-system

# Ceph UI can be found at: https://192.168.50.250:8443/#/login
# User=admin and Password can be found here: kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

# Network Access

For a talos setup the endpoints are accessible to the local network, so no tunnels are required.

But you do need to provide a static DNS name mapping:

```
192.168.50.253  ceph.dev.bigbang.mil
192.168.50.252  keycloak.dev.bigbang.mil
192.168.50.252  openldap.dev.bigbang.mil
192.168.50.251  kiali.dev.bigbang.mil
192.168.50.251  grafana.dev.bigbang.mil
192.168.50.251  prometheus.dev.bigbang.mil
192.168.50.251  alertmanager.dev.bigbang.mil
192.168.50.251  headlamp.dev.bigbang.mil
192.168.50.251  neuvector.dev.bigbang.mil
192.168.50.251  twistlock.dev.bigbang.mil
192.168.50.251  chat.dev.bigbang.mil
```
