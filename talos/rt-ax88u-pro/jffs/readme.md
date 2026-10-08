# AX-RT88U met Merlin software

## SSH

```
ssh adm820@192.168.50.1
adm820@192.168.50.1's password: <<<
```

## tcpdump

Is niet standaard aanwezig maar kun je installeren:

1. USB stick met ext4 filesystem inpluggen in de router
2. ```amtm``` starten
3. In amtm met ep opkg installeren
4. Dan ```opkg update``` en ```opkg install tcpdump```

## Proxmox / Talos homelab

### VLANs

Toevoegen VLANs voor Proxmox / Talos / Kubernetes

```
# Op welke eth poort zit de RT-AX53U? Op eth3 (en eth2 is die van de cameras)

Experiment (moet eth1 zijn):

ip link add link eth3 name eth3.20 type vlan id 20
ip -d link show eth3.20
48: eth3.20@eth3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether c8:7f:54:e4:f2:18 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 0 maxmtu 65535 
    vlan protocol 802.1Q id 20 <REORDER_HDR> addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 
brctl addbr br20
brctl addif br20 eth3.20
ip link set eth3.20 up
ip link set br20 up
ip addr add 192.168.20.1/24 dev br20
ip addr show br20
49: br20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether c8:7f:54:e4:f2:18 brd ff:ff:ff:ff:ff:ff
    inet 192.168.20.1/24 scope global br20
       valid_lft forever preferred_lft forever

brctl show br20
bridge name	bridge id		STP enabled	interfaces
br20		8000.c87f54e4f218	no		eth3.20

Als ik een ping doe vanuit een alpine iso / vm:

ip addr add 192.168.20.100/24 dev eth0
ip link set eth0 up
ping 192.168.20.1

Dan krijg ik op de proxmox host:

root@p1:~# tcpdump -eni nic0 vlan 20
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on nic0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
11:11:34.434823 bc:24:11:7a:80:84 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 46: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 28
11:11:35.446694 bc:24:11:7a:80:84 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 46: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 28
11:11:36.470729 bc:24:11:7a:80:84 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 46: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 28
11:11:38.435548 bc:24:11:7a:80:84 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 46: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 28

En ook op de RT-AX88U-Pro:

adm820@RT-AX88U_Pro-F218:/tmp/home/root# tcpdump -eni eth3 vlan 20
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth3, link-type EN10MB (Ethernet), snapshot length 262144 bytes
21:23:00.795819 bc:24:11:b3:a7:b7 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 60: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 42
21:23:01.819854 bc:24:11:b3:a7:b7 > ff:ff:ff:ff:ff:ff, ethertype 802.1Q (0x8100), length 60: vlan 20, p 0, ethertype ARP (0x0806), Request who-has 192.168.20.1 tell 192.168.20.100, length 42
```

## KPN IPTV

### Aanpassingen jffs scripts

LAN poort 3 (eth2) configureren als untagged (vlan 501) en toevoegen aan br1 (guestnet).

