# Guideline to setup trust

```
# Fetch the chain
kubectl -n istio-gateway get secret public-cert -o jsonpath='{.data.tls\.crt}' | base64 -d > ./ca/ca.crt

# Check and leave only the root (CA:TRUE)
openssl x509 -in ./ca/ca.crt -noout -subject -dates -ext basicConstraints

sudo install -m 0644 ./ca/ca.crt /usr/local/share/ca-certificates/bigbang-dev.crt
sudo update-ca-certificates
```