
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

$$20261007$$

+ talos image bump
+ api version alphav1 deprecated
+ eerst alleen control planes doen; kijken of dat up komt op vlan20
+ ntp session timeout :4460
- node p3 valt weg; mogelijk EEE related
- ai node label toevoegen en drivers aanzetten
- ai-node heeft geen storage?
- 

