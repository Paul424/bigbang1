# Kind

## WSL2 Config

Override for WSL2 confs
```
# C:\Users\<your-username>\.wslconfig
[wsl2]
kernelCommandLine = cgroup_no_v1=all
memory=24GB
```

## OS Configs

Increase the max open file limit
```
# /etc/systemd/system.conf
DefaultLimitNOFILE=524288
```

Increase max file watches (See: https://open-docs.neuvector.com/basics/requirements#adding-scaling-constraints-for-large-workload-environments)
```
# Append to /etc/sysctl.d/99-sysctl.conf and reload using sysctl -p
fs.inotify.max_queued_events=616384
fs.inotify.max_user_instances=512
fs.inotify.max_user_watches=786432
```

# Setup

```
bash ./run.sh up_kind <CLUSTER-NAME>
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
172.18.0.6      alertmanager.dev.bigbang.mil
172.18.0.6      headlamp.dev.bigbang.mil
```

And test access from the terminal using:
```
curl -I https://kiali.dev.bigbang.mil/kiali/
HTTP/2 200 
```
