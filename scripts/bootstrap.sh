#!/bin/bash
set -euxo pipefail

BASE=$(dirname $(dirname $(realpath $0)))
CLUSTER_NAME=${1:-bb9};

SOPS_KEY_NAME="dev.bigbang.mil"
export REPO1_LOCATION=$BASE/upstream

# Create the namespace for initial secrets
kubectl create namespace bigbang --dry-run=client -o yaml | kubectl apply -f -

# Export the SOPS key to the cluster
gpg --export-secret-key --armor "${SOPS_KEY_NAME}" | kubectl create secret generic sops-gpg -n bigbang --from-file=bigbangkey.asc=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -

# Git (private) repo credentials
kubectl create secret generic private-git -n bigbang \
    --from-literal=username=$REGISTRY_UPSTREAM_USERNAME \
    --from-literal=password=$REGISTRY_UPSTREAM_PAT \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy flux
if [ ! -d "$REPO1_LOCATION/bigbang" ]; then
  echo "Cloning repository into $REPO1_LOCATION/bigbang..."
  git clone https://repo1.dso.mil/big-bang/bigbang.git $REPO1_LOCATION/bigbang
else
  echo "Directory $REPO1_LOCATION/bigbang already exists. Skipping clone."
fi
$REPO1_LOCATION/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_TOKEN

# The top level reconciler
kubectl apply -f $BASE/environments/dev/bigbang.yaml




# function up_hacks {
#     CLUSTER_NAME=${1}
#     kubectl apply -f $BASE/manifests/dev-clusterrolebinding.yaml
# }

# function up_kc_config {
#     # Create (update) a kube config context using OIDC
#     #
#     # Example: 
#     #   kubectl --context barney get pods -A
#     #   [OK]
#     #
#     #   kubectl --context barney delete pod -n kiali kiali-7ccd646bb-ltgxs
#     #   Error from server (Forbidden): pods "kiali" is forbidden: User "https://keycloak.dev.bigbang.mil/auth/realms/me-yoda#barney" cannot delete resource "pods" in API group "" in the namespace "kiali"
#     #
#     #   kubectl --context fred delete pod -n kiali kiali-7ccd646bb-ltgxs
#     #   pod "kiali-7ccd646bb-ltgxs" deleted from kiali namespace
#     local USERNAME=${1};
#     local CLUSTER_NAME=${2};
#     local CLIENT_ID=kubernetes
#     local ISSUER=https://keycloak.dev.bigbang.mil/auth/realms/me-yoda
#     local ENDPOINT=$ISSUER/protocol/openid-connect/token
#     local ID_TOKEN=$(curl -k -X POST $ENDPOINT \
#         -d grant_type=password \
#         -d client_id=$CLIENT_ID \
#         -d username=$USERNAME \
#         -d password=$USERNAME \
#         -d scope=openid \
#         -d response_type=id_token | jq -r '.id_token')
#     local REFRESH_TOKEN=$(curl -k -X POST $ENDPOINT \
#         -d grant_type=password \
#         -d client_id=$CLIENT_ID \
#         -d username=$USERNAME \
#         -d password=$USERNAME \
#         -d scope=openid \
#         -d response_type=id_token | jq -r '.refresh_token')
#     local CA_DATA=$(kubectl get secret -n keycloak keycloak-keycloak-tlscert -o json | jq -r '.data."tls.crt"')
#     kubectl config set-credentials $USERNAME \
#         --auth-provider=oidc \
#         --auth-provider-arg=client-id=$CLIENT_ID \
#         --auth-provider-arg=idp-issuer-url=$ISSUER \
#         --auth-provider-arg=id-token=$ID_TOKEN \
#         --auth-provider-arg=refresh-token=$REFRESH_TOKEN \
#         --auth-provider-arg=idp-certificate-authority-data=$CA_DATA
#     kubectl config set-context $USERNAME --cluster=$CLUSTER_NAME --user=$USERNAME
# }



# case "$COMMAND" in
#     bootstrap)
#         CLUSTER_NAME=${1:-bb9};
#         shift
#         bootstrap $CLUSTER_NAME
#         ;;

#     up_hacks)
#     CLUSTER_NAME=${1:-bb9};
#         shift
#         up_hacks $CLUSTER_NAME
#         ;;

#     up_kc_config)
#         USERNAME=${1:-barney};
#         CLUSTER_NAME=${2:-bb9};
#         shift
#         up_kc_config $USERNAME $CLUSTER_NAME
#         ;;

#     *)
#         echo "Invalid argument"
#         exit 1
#         ;;
# esac
