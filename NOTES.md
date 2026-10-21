$$20261021$$

Met twee interfaces en policy routing kan strict mode pakketten droppen. Zet zo nodig net.ipv4.conf.all.rp_filter: "2" in machine.sysctls.




adm820@RT-AX88U_Pro-F218:/jffs/scripts# ip route get 192.168.30.100
192.168.30.100 dev br30 src 192.168.30.1 uid 0 
    cache 
adm820@RT-AX88U_Pro-F218:/jffs/scripts# ip -br addr | grep 192.168.30
br30             UP             192.168.30.1/24 
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -L SVC30 -v -n --line-numbers
Chain SVC30 (1 references)
num   pkts bytes target     prot opt in     out     source               destination         
1     4882 2260K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
2        5   300 ACCEPT     tcp  --  br0    br30    192.168.50.0/24      192.168.30.0/24      multiport dports 80,443 ctstate NEW
3     2295  360K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0           
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -t nat -L POSTROUTING -v -n --line-numbers | head
Chain POSTROUTING (policy ACCEPT 8052 packets, 654K bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1        1    60 MASQUERADE  tcp  --  *      br30    192.168.50.0/24      192.168.30.0/24      multiport dports 80,443
2      126 14504 MASQUERADE  all  --  *      vlan4   0.0.0.0/0            0.0.0.0/0           
3    2073K  184M PUPNP      all  --  *      ppp0    0.0.0.0/0            0.0.0.0/0           
4    69226   21M MASQUERADE  all  --  *      ppp0   !86.88.91.166         0.0.0.0/0           
5      117  7020 MASQUERADE  all  --  *      vlan6  !169.254.137.240      0.0.0.0/0           
6     2684  337K MASQUERADE  all  --  *      br0     192.168.50.0/24      192.168.50.0/24     
7        0     0 MASQUERADE  all  --  *      ppp0    192.168.20.0/24      0.0.0.0/0           
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -L FORWARD -v -n --line-numbers | head -20
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1     8016 2967K SVC30      all  --  *      *       0.0.0.0/0            0.0.0.0/0           
2    5167K 3656M TALOS20    all  --  *      *       0.0.0.0/0            0.0.0.0/0           
3    4274K 3306M IPSEC_DROP_SUBNET_ICMP  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
4    4274K 3306M IPSEC_STRONGSWAN  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
5    2271K 3079M ACCEPT     udp  --  *      *       0.0.0.0/0            224.0.0.0/4         
6     510K   31M TCPMSS     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcpflags: 0x06/0x02 TCPMSS clamp to PMTU
7       25  7690 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
8    2003K  226M WGSF       all  --  *      *       0.0.0.0/0            0.0.0.0/0           
9    2003K  226M OVPNSF     all  --  *      *       0.0.0.0/0            0.0.0.0/0           
10    6647 2602K WGNPControls  all  --  br1    *       0.0.0.0/0            0.0.0.0/0           
11    4927 2499K ACCEPT     all  --  br1    ppp0    0.0.0.0/0            0.0.0.0/0           
12     124 10095 DROP       all  --  !br0   ppp0    0.0.0.0/0            0.0.0.0/0           
13    1720  103K WGNPControls  all  --  br1    *       0.0.0.0/0            0.0.0.0/0           
14      32  1920 ACCEPT     all  --  br1    vlan6   0.0.0.0/0            0.0.0.0/0           
15       2   120 DROP       all  --  !br0   vlan6   0.0.0.0/0            0.0.0.0/0           
16       0     0 ACCEPT     all  --  br0    br0     0.0.0.0/0            0.0.0.0/0           
17   11774  857K DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
18       0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate DNAT
<hier curl command gedaan>
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -L SVC30 -v -n --line-numbers
Chain SVC30 (1 references)
num   pkts bytes target     prot opt in     out     source               destination         
1     5902 2757K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
2       10   600 ACCEPT     tcp  --  br0    br30    192.168.50.0/24      192.168.30.0/24      multiport dports 80,443 ctstate NEW
3     2640  444K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0           
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -t nat -L POSTROUTING -v -n --line-numbers | head
Chain POSTROUTING (policy ACCEPT 9136 packets, 742K bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1        2   120 MASQUERADE  tcp  --  *      br30    192.168.50.0/24      192.168.30.0/24      multiport dports 80,443
2      126 14504 MASQUERADE  all  --  *      vlan4   0.0.0.0/0            0.0.0.0/0           
3    2074K  184M PUPNP      all  --  *      ppp0    0.0.0.0/0            0.0.0.0/0           
4    69326   21M MASQUERADE  all  --  *      ppp0   !86.88.91.166         0.0.0.0/0           
5      117  7020 MASQUERADE  all  --  *      vlan6  !169.254.137.240      0.0.0.0/0           
6     2686  337K MASQUERADE  all  --  *      br0     192.168.50.0/24      192.168.50.0/24     
7        0     0 MASQUERADE  all  --  *      ppp0    192.168.20.0/24      0.0.0.0/0           
adm820@RT-AX88U_Pro-F218:/jffs/scripts# iptables -L FORWARD -v -n --line-numbers | head -20
Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination         
1     8649 3214K SVC30      all  --  *      *       0.0.0.0/0            0.0.0.0/0           
2    5168K 3656M TALOS20    all  --  *      *       0.0.0.0/0            0.0.0.0/0           
3    4274K 3306M IPSEC_DROP_SUBNET_ICMP  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
4    4274K 3306M IPSEC_STRONGSWAN  all  --  *      *       0.0.0.0/0            0.0.0.0/0           
5    2271K 3079M ACCEPT     udp  --  *      *       0.0.0.0/0            224.0.0.0/4         
6     510K   31M TCPMSS     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcpflags: 0x06/0x02 TCPMSS clamp to PMTU
7       25  7690 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
8    2003K  226M WGSF       all  --  *      *       0.0.0.0/0            0.0.0.0/0           
9    2003K  226M OVPNSF     all  --  *      *       0.0.0.0/0            0.0.0.0/0           
10    6647 2602K WGNPControls  all  --  br1    *       0.0.0.0/0            0.0.0.0/0           
11    4927 2499K ACCEPT     all  --  br1    ppp0    0.0.0.0/0            0.0.0.0/0           
12     129 10395 DROP       all  --  !br0   ppp0    0.0.0.0/0            0.0.0.0/0           
13    1720  103K WGNPControls  all  --  br1    *       0.0.0.0/0            0.0.0.0/0           
14      32  1920 ACCEPT     all  --  br1    vlan6   0.0.0.0/0            0.0.0.0/0           
15       2   120 DROP       all  --  !br0   vlan6   0.0.0.0/0            0.0.0.0/0           
16       0     0 ACCEPT     all  --  br0    br0     0.0.0.0/0            0.0.0.0/0           
17   11774  857K DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0            state INVALID
18       0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate DNAT


ana logger=authn.service traceID=20d71dfe31b2d2a905cbb907b181c7f0 t=2026-10-21T09:10:42.736330908Z level=error msg="Failed to authenticate request" client=auth.client.generic_oauth error="[auth.oauth.token.exchange │
│ ] failed to exchange code to token: Post \"https://keycloak.dev.bigbang.mil/auth/realms/me-yoda/protocol/openid-connect/token\": dial tcp: lookup keycloak.dev.bigbang.mil on 10.96.0.10:53: no such host"                 │
│ grafan



$$20261020$$

Oplossing A (Aanbevolen): Configureer Symmetric Routing op de node (bijvoorbeeld met ip rule en ip route tabellen per VLAN) zodat verkeer dat binnenkomt op de VLAN-interface ook verplicht via de gateway van datzelfde VLAN beantwoordt.

$$20261017$$

Tbv vlan debug: netshoot pod als daemonset draaien op hostnetwork

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

authservice:

pods "authservice-84c5bc4dc-v77sq" is forbidden: violates PodSecurity                                                                                                                                │
│       "baseline:latest": non-default capabilities (container "istio-init" must not                                                                                                                                 │
│       include "NET_ADMIN", "NET_RAW" in securityContext.capabilities.add)'

For now lets simply set enforce=privileged
Then later (BB4) we can switch to istio cni

prometheus:

="Failed to apply configuration" err="unable to read CA cert: unable to read file /etc/prom-certs/root-cert.pem: open /etc/prom-certs/root-cert.pem: no such file or directory"                                                                            

msg="Fatal error" err="error loading config from \"/etc/prometheus/config_out/prometheus.env.yaml\": one or more errors occurred while applying the  │
│ new configuration (--config.file=\"/etc/prometheus/config_out/prometheus.env.yaml\")" 

.Values.alertmanager.alertmanagerSpec.tlsConfig
Ik vermoed dat ns monitoring toch injected draaide! Hierdoor kwam de sidecar etc...
  istio-injection: enabled
Eerste ven gemakkelijk terugzetten en bekijken.
Trouwens k8s-resources komt toch te vervallen door cluster op privileged ;-)


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
- ai node label toevoegen en drivers aanzetten
