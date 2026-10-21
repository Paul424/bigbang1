# DNS

On the cluster we run a bind9 server to resolve any of the hostnames within the domain (.dev.bigbang.mil). This service is exposed using type: LoadBalancer on IP 192.168.30.150.

Talos is then configured to consider the bind9 server as a resolved.

In addition the router is configured to forward DNS requests to bind9 for the domain. This is required because upstream nameservers can't resolve the internal names but still have a valid response (NXDOMAIN).

```
# /jffs/configs/dnsmasq.conf.add
server=/dev.bigbang.mil/192.168.30.150
```

## Test

```
# Through VLAN20 gateway
dig @192.168.20.1 keycloak.dev.bigbang.mil

# Directly on bind9
dig @192.168.30.150 keycloak.dev.bigbang.mil

# Inspect talos node resolvers
talosctl -n talos-wrk2 get resolvers
```
