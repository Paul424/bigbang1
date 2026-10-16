
$$20261016$$

- als ik lokaal een bootstrap.sh doe dan komt flux v1.6.4 op en dat is ok; de upgrade
- dan echter komt er een GitRepo bigbang @ 3.23.0 waardoor de flux tooling weer wordt gedowngrade

bootstrap 
=> $BASE/environments/dev/bigbang.yaml
    GitRepository-env (uit Paul424 repo)
    Met een kustomization /environments/dev uit die repo (Paul424)
    => https://repo1.dso.mil/platform-one/big-bang/bigbang.git/base?ref=3.34.0
      GitRepository bigbang
      HelmRelease
    => flux-components.yaml
      Kustomization flux-components uit repo bigbang met path ./base/flux

Hoe kan de GitRepo bigbang nu terugvallen op @3.23.0 ?????
Ook na suspend van flux-components blijft de bigbang gitrepo hangen op tag 3.23.0
Ah, nee wacht nu komt hij toch; nu naar 3.34.0
En ook de bb-env is nu applied!
Kijken wat resume doet? Ok nu applied nu direct v3.34.0

$$20261015$$

- proxmox confs gemaakt om de nvidia pci device raw door te geven.
- de gpuoperator toevoegen als package
- nvidia-smi toevoegen als toolbox container


$$20261014$$

+ talos reboot probleem komt wellicht door nvidia extensies:
    - node p2 uitgerust met nieuwe 1.14.2 image zonder nvidia ext, sinds 19:51 Ready gekomen
    - tevens log / tail laten lopen voor ctl1 (kijken of we dmesg kunnen capturen)
  idd bij gewone image zonder de nvidia ext is er geen reboot

$$20261013$$

daemonset-controller  Error creating: pods "metallb-speaker-r9j7b" is forbidden: violates PodSecurity "baseline:latest": non-default capabilities (containers "speake │
│ r", "frr" must not include "NET_ADMIN", "NET_RAW", "SYS_ADMIN" in securityContext.capabilities.add), host namespaces (hostNetwork=true), hostPort (containers "speaker", "frr-metrics" use hostPorts 7472, 7473, 79 │
│ 46)

metallb/metallb-speaker

daemonset-controller  Error creating: pods "rook-ceph.cephfs.csi.ceph.com-nodeplugin-tc9rz" is forbidden: violates PodSecurity "baseline:latest": non-default capabi │
│ lities (container "csi-cephfsplugin" must not include "SYS_ADMIN" in securityContext.capabilities.add), host namespaces (hostNetwork=true), hostPath volumes (volumes "host-dev", "host-sys", "host-run-mount", "li │
│ b-modules", "plugin-dir", "plugin-mount-dir", "pods-mount-dir", "registration-dir", "ceph-csi-mountinfo"), privileged (containers "csi-cephfsplugin", "driver-registrar" must not set securityContext.privileged=tr │
│ ue)

kubectl label namespace rook-ceph \
  pod-security.kubernetes.io/enforce=privileged \
  --overwrite

Beide configured in bb config.yaml met ns label


bind9 192.168.50.250 => 192.168.30.150
istio gw 192.168.50.251 => 192.168.30.100
istio gw passthrough 192.168.50.252 => 192.168.30.101

  Warning  announceFailed  3m14s                  metallb-speaker     the interfaces specified by LB IP "192.168.30.101" doesn't exist in assigned node "talos-wrk1" with protocol "layer2"                         │
│   Normal   nodeAssigned    3m14s                  metallb-speaker     announcing from node "talos-wrk1" with protocol "layer2" 

 spec:                                                                                                                                                                                                               │
│   interfaces:                                                                                                                                                                                                       │
│   - enp1s0.30                                                                                                                                                                                                       │
│   ipAddressPools:                                                                                                                                                                                                   │
│   - metallb-config-default-pool                   

talosctl get links --nodes $WRK1_IP
NODE            NAMESPACE   TYPE         ID                VERSION   ALIAS   TYPE       KIND     HW ADDR                                           OPER STATE   LINK STATE
192.168.20.20   network     LinkStatus   bond0             1                 ether      bond     42:cb:6c:0b:85:4e                                 down         false
192.168.20.20   network     LinkStatus   cali1c677ed926e   2                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   cali1ec52e18bd0   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   cali7b805ddede9   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   cali8ede8a4ec3c   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   cali98bc07a5030   2                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   calia13db862b1f   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   calib67df7eaeb1   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   calie36b3fde4e3   1                 ether      veth     ee:ee:ee:ee:ee:ee                                 up           true
192.168.20.20   network     LinkStatus   dummy0            1                 ether      dummy    ba:a1:5f:6e:d3:c1                                 down         false
192.168.20.20   network     LinkStatus   ens18             2                 ether               bc:24:11:f7:7e:12                                 up           true
192.168.20.20   network     LinkStatus   ens18.30          2                 ether      vlan     bc:24:11:f7:7e:12                                 up           true

{"level":"info","ts":"2026-10-13T12:50:16.015Z","msg":"HelmChart/bigbang/bigbang-istiod with SourceRef 'GitRepository/bigbang/istiod' is in-sync","controller":"helmrelease","controllerGroup":"helm.toolkit.fluxcd.io","controllerKind":"HelmRelease","HelmRelease":{"name":"istiod","namespace":"bigbang"},"namespace":"bigbang","name":"istiod","reconcileID":"d0c7dd5a-2118-4c63-aa9f-a22490b3f472"}
{"level":"info","ts":"2026-10-13T12:50:16.033Z","msg":"checking 2 dependencies","controller":"helmrelease","controllerGroup":"helm.toolkit.fluxcd.io","controllerKind":"HelmRelease","HelmRelease":{"name":"istiod","namespace":"bigbang"},"namespace":"bigbang","name":"istiod","reconcileID":"d0c7dd5a-2118-4c63-aa9f-a22490b3f472"}
{"level":"info","ts":"2026-10-13T12:50:16.039Z","msg":"all dependencies are ready","controller":"helmrelease","controllerGroup":"helm.toolkit.fluxcd.io","controllerKind":"HelmRelease","HelmRelease":{"name":"istiod","namespace":"bigbang"},"namespace":"bigbang","name":"istiod","reconcileID":"d0c7dd5a-2118-4c63-aa9f-a22490b3f472"}
{"level":"info","ts":"2026-10-13T12:50:16.455Z","msg":"would violate PodSecurity \"restricted:latest\": seccompProfile (pod or container \"discovery\" must set securityContext.seccompProfile.type to \"RuntimeDefault\" or \"Localhost\")","controller":"helmrelease","controllerGroup":"helm.toolkit.fluxcd.io","controllerKind":"HelmRelease","HelmRelease":{"name":"istiod","namespace":"bigbang"},"namespace":"bigbang","name":"istiod","reconcileID":"d0c7dd5a-2118-4c63-aa9f-a22490b3f472"}

Issue with monitoring helmrelease:

    Message:               Helm install failed for release monitoring/monitoring-monitoring with chart monitoring@83.4.0-bb.1: failed pre-install: 1 error occurred:                                                │
│                            * timed out waiting for the condition       

we need to template out monitoring to figure out what the pre-install condition really is...
Het is een job die ook namespace priviliged behoeft.
Hier lastiger omdat ns door helm wordt aangemaakt (als niet bestaat)
Moeten we dus ergens toevoegen; maar... dependsOn is dan ook nodig vanuit monitoring.
Ok hook gevonden voor de depends=On, en ik ga de k8s-resources chart gebruiken voor de ns creatie.

$$20261007$$

+ talos image bump
+ api version alphav1 deprecated
+ eerst alleen control planes doen; kijken of dat up komt op vlan20
+ ntp session timeout :4460
- node p3 valt weg; mogelijk EEE related
- ai node label toevoegen en drivers aanzetten
- ai-node heeft geen storage?
- 

