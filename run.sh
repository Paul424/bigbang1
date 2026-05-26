#!/bin/bash
set -x

if [ $# -eq 0 ]; then
    echo "Usage: $0 {up_kind|up_kind_lb|down_kind|generate_sops_keys|bootstrap} [naam]"
    exit 1
fi

BASE=$(dirname $(realpath $0))
COMMAND="$1"
shift

SOPS_KEY_NAME="dev.bigbang.mil"

function up_kind {
    CLUSTER_NAME=${1}
    kind create cluster --config=kind.yaml --name $CLUSTER_NAME --verbosity 2
    kubectl config view --minify=false --raw=true > ~/.kube/${CLUSTER_NAME}-dev-quickstart-config
}

function down_kind {
    CLUSTER_NAME=${1}
    kind delete cluster --name $CLUSTER_NAME
}

function up_kind_lb {
    # Install cloud-provider-kind from https://github.com/kubernetes-sigs/cloud-provider-kind/releases
    if ! [ -x "$(command -v cloud-provider-kind)" ]; then
        echo 'Error: cloud-provider-kind is not installed.' >&2
        exit 1
    fi
    cloud-provider-kind > ./log/cloud-provider-kind.log 2>&1
}

function generate_sops_keys {
    KEY_COMMENT="flux secrets"

    gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Comment: ${KEY_COMMENT}
Name-Real: ${SOPS_KEY_NAME}
EOF

FP=$(gpg --fingerprint --with-colons "$SOPS_KEY_NAME" | awk -F: '/^fpr:/ { print $10; exit }')
if [ -z "$FP" ]; then
    echo "Fingerprint not found"
    exit 1
else
    echo "Fingerprint: $FP"
fi

# Set the finger-print in the .sops.yaml config.
sed -i "s/pgp: .*/pgp: ${FP}/" $BASE/.sops.yaml

}

function bootstrap {
    CLUSTER_NAME=${1}
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
    git clone https://repo1.dso.mil/big-bang/bigbang.git $REPO1_LOCATION/bigbang
    $REPO1_LOCATION/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_PASSWORD

    # The top level reconciler
    kubectl apply -f environments/dev/bigbang.yaml
}

function up_hacks {
    CLUSTER_NAME=${1}
    kubectl apply -f $BASE/manifests/dev-clusterrolebinding.yaml
}

function up_kc_config {
    # Create (update) a kube config context using OIDC
    #
    # Example: 
    #   kubectl --context barney get pods -A
    #   [OK]
    #
    #   kubectl --context barney delete pod -n kiali kiali-7ccd646bb-ltgxs
    #   Error from server (Forbidden): pods "kiali" is forbidden: User "https://keycloak.dev.bigbang.mil/auth/realms/me-yoda#barney" cannot delete resource "pods" in API group "" in the namespace "kiali"
    #
    #   kubectl --context fred delete pod -n kiali kiali-7ccd646bb-ltgxs
    #   pod "kiali-7ccd646bb-ltgxs" deleted from kiali namespace
    local USERNAME=${1};
    local CLUSTER_NAME=${2};
    local CLIENT_ID=kubernetes
    local ISSUER=https://keycloak.dev.bigbang.mil/auth/realms/me-yoda
    local ENDPOINT=$ISSUER/protocol/openid-connect/token
    local ID_TOKEN=$(curl -k -X POST $ENDPOINT \
        -d grant_type=password \
        -d client_id=$CLIENT_ID \
        -d username=$USERNAME \
        -d password=$USERNAME \
        -d scope=openid \
        -d response_type=id_token | jq -r '.id_token')
    local REFRESH_TOKEN=$(curl -k -X POST $ENDPOINT \
        -d grant_type=password \
        -d client_id=$CLIENT_ID \
        -d username=$USERNAME \
        -d password=$USERNAME \
        -d scope=openid \
        -d response_type=id_token | jq -r '.refresh_token')
    local CA_DATA=$(kubectl get secret -n keycloak keycloak-keycloak-tlscert -o json | jq -r '.data."tls.crt"')
    kubectl config set-credentials $USERNAME \
        --auth-provider=oidc \
        --auth-provider-arg=client-id=$CLIENT_ID \
        --auth-provider-arg=idp-issuer-url=$ISSUER \
        --auth-provider-arg=id-token=$ID_TOKEN \
        --auth-provider-arg=refresh-token=$REFRESH_TOKEN \
        --auth-provider-arg=idp-certificate-authority-data=$CA_DATA
    kubectl config set-context $USERNAME --cluster=$CLUSTER_NAME --user=$USERNAME
}



case "$COMMAND" in
    up_kind)
        CLUSTER_NAME=${1:-bb1};
        shift
        up_kind $CLUSTER_NAME
        ;;
    
    down_kind)
        CLUSTER_NAME=${1:-bb1};
        shift
        down_kind $CLUSTER_NAME
        ;;

    up_kind_lb)
        up_kind_lb
        ;;
    
    generate_sops_keys)
        generate_sops_keys
        ;;

    bootstrap)
        CLUSTER_NAME=${1:-bb1};
        shift
        bootstrap $CLUSTER_NAME
        ;;

    up_hacks)
    CLUSTER_NAME=${1:-bb1};
        shift
        up_hacks $CLUSTER_NAME
        ;;

    up_kc_config)
        USERNAME=${1:-barney};
        CLUSTER_NAME=${2:-bb1};
        shift
        up_kc_config $USERNAME $CLUSTER_NAME
        ;;

    *)
        echo "Invalid argument"
        echo "Usage: $0 {generate_sops_keys|bootstrap} [naam]"
        exit 1
        ;;
esac
