# KinD cluster

## Create a cluster
```
kind create cluster --config=kind.yaml --name bb9 --verbosity 2
```

## Remove cluster
```
kind delete cluster --name bb9
```

## Load balancer support
```
cloud-provider-kind > ./log/cloud-provider-kind.log 2>&1
```
