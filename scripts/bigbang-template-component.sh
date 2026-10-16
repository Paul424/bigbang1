#!/bin/bash
set -euxo pipefail

BASE=$(dirname $(dirname $(realpath $0)))
COMPONENT=${1:-monitoring};
OUTPUT=${2:-$BASE/out/$COMPONENT};

function template_bigbang {
    OUTPUT=${1}
    echo "Templating bigbang to $OUTPUT"
    rm -rf $OUTPUT
    mkdir -p $OUTPUT

    # Extract the values.yaml from the decrypted secrets
    cat $BASE/environments/base/common-bb-secret.yaml | yq e '.stringData."values.yaml"' > $OUTPUT/values-common-bb-secret.yaml
    cat $BASE/environments/dev/secrets/dev-bb-secret.yaml | yq e '.stringData."values.yaml"' > $OUTPUT/values-dev-bb-secret.yaml

    helm template $BASE/upstream/bigbang/chart \
        -n bigbang \
        --create-namespace \
        -f $OUTPUT/values-common-bb-secret.yaml \
        -f $BASE/environments/base/config.yaml \
        -f $OUTPUT/values-dev-bb-secret.yaml \
        -f $BASE/environments/dev/config.yaml \
        --kube-version 1.37.1 \
        --output-dir $OUTPUT
}

function checkout_component_repo {
    local COMPONENT=${1}
    local GIT_REMOTE=${2}
    local ARG_VERSION=${3}
    local REPO_PATH=$BASE/upstream/${COMPONENT}
    if [[ ! -d ${REPO_PATH} ]]; then
        mkdir -p ${REPO_PATH}
        git clone $GIT_REMOTE ${REPO_PATH}
        pushd ${REPO_PATH}
    else
        pushd ${REPO_PATH}
    fi
    git fetch -a
    if [[ "${ARG_VERSION}" == "latest" ]]; then
        ARG_VERSION=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
    git checkout ${ARG_VERSION}
    popd
}

# Umbrella chart to generate the values (and gitops confs)
template_bigbang $OUTPUT

# Extract the values from gitops resources
# equivalent of:
# kubectl get secret -n bigbang bigbang-kiali-values -o json | jq -r '.data.defaults' | base64 -d
cat $OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.common' > $OUTPUT/values-common.yaml
cat $OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.defaults' > $OUTPUT/values-defaults.yaml
cat $OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.overlays' > $OUTPUT/values-overlays.yaml

# Setup clone for the upstream (from GitRepository resource)
GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION

# Template out for the component
echo "Templating $COMPONENT to $OUTPUT"
helm template $BASE/upstream/$COMPONENT/chart \
    -f $OUTPUT/values-common.yaml \
    -f $OUTPUT/values-defaults.yaml \
    -f $OUTPUT/values-overlays.yaml \
    -n $NAMESPACE \
    --output-dir $OUTPUT




# function template_bigbang_test_patches {
#     OUTPUT=${1}
#     echo "Templating bigbang to $OUTPUT"
#     rm -rf ./$OUTPUT
#     helm template ./upstream/big-bang/bigbang/chart \
#         -n bigbang \
#         --create-namespace \
#         --set registryCredentials.username=${REGISTRY1_USERNAME} \
#         --set registryCredentials.password=${REGISTRY1_TOKEN} \
#         --set helmRepositories[0].username=${REGISTRY_UPSTREAM_USERNAME} \
#         --set helmRepositories[0].password=${REGISTRY_UPSTREAM_PAT} \
#         --set helmRepositories[1].username=${REGISTRY_UPSTREAM_USERNAME} \
#         --set helmRepositories[1].password=${REGISTRY_UPSTREAM_PAT} \
#         -f $BASE/bigbang.yaml \
#         -f ./upstream/big-bang/bigbang/chart/ingress-certs.yaml \
#         --output-dir ./$OUTPUT
#         # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/dev-sso-values.yaml
#         # -f ./upstream/big-bang/bigbang/docs/reference/configs/example/policy-overrides-k3d.yaml
# }

# function template_component_extract_values {
#     local OUTPUT=${1}
#     local COMPONENT=${2}
#     echo "Extracting values for $COMPONENT from $OUTPUT"
#     mkdir -p ./$OUTPUT/$COMPONENT
#     # equivalent of:
#     # kubectl get secret -n bigbang bigbang-kiali-values -o json | jq -r '.data.defaults' | base64 -d
#     cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.common' > ./$OUTPUT/$COMPONENT/values-common.yaml
#     cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.defaults' > ./$OUTPUT/$COMPONENT/values-defaults.yaml
#     cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData.overlays' > ./$OUTPUT/$COMPONENT/values-overlays.yaml
#     # wrapper exceptions
#     cat ./$OUTPUT/bigbang/templates/$COMPONENT/values.yaml | yq e '.stringData."values.yaml"' > ./$OUTPUT/$COMPONENT/values.yaml
# }

# function template_wrapper_component_extract_values {
#     local OUTPUT=${1}
#     local COMPONENT=${2}
#     echo "Extracting values for $COMPONENT (wrapper) from $OUTPUT"
#     mkdir -p ./$OUTPUT/wrapper
#     cat ./$OUTPUT/bigbang/templates/wrapper/values.yaml | yq e '.stringData."values.yaml"' > ./$OUTPUT/wrapper/values.yaml
#     mkdir -p ./$OUTPUT/$COMPONENT
#     cat ./$OUTPUT/wrapper/values.yaml | yq e '.package.values' > ./$OUTPUT/$COMPONENT/values.yaml
# }



# function template_wrapper_component {
#     local OUTPUT=${1}
#     local COMPONENT=${2}

#     # Umbrella chart to generate the values (and gitops confs)
#     template_bigbang $OUTPUT

#     # Extract the values from gitops resources
#     template_wrapper_component_extract_values $OUTPUT $COMPONENT

#     # Setup clone for the wrapper upstream (from GitRepository resource)
#     # Extract remote from the GitRepository resource
#     GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
#     ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
#     NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/wrapper/helmrelease.yaml)
#     checkout_component_repo wrapper $GIT_REMOTE $ARG_VERSION
    
#     # Template out for the wrapper
#     echo "Templating wrapper ($COMPONENT) to $OUTPUT/wrapper"
#     # rm -rf ./$OUTPUT/$COMPONENT
#     helm template ./upstream/wrapper/chart \
#         -f ./$OUTPUT/wrapper/values.yaml \
#         -n $NAMESPACE \
#         --output-dir ./$OUTPUT

#     # Setup clone for the component upstream (from GitRepository resource)
#     # todo: Needs support for git/helmrepo upstream :-(

#     # Template out for the function
#     # todo...
# }

# function install_component {
#     local OUTPUT=${1}
#     local COMPONENT=${2}

#     # Umbrella chart to generate the values (and gitops confs)
#     template_bigbang $OUTPUT

#     # Extract the values from gitops resources
#     template_component_extract_values $OUTPUT $COMPONENT

#     # Setup clone for the upstream (from GitRepository resource)
#     case "$COMPONENT" in
#         *)
#             # Extract remote from the GitRepository resource
#             GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
#             ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/$COMPONENT/gitrepository.yaml)
#             NAMESPACE=$(yq e '.spec.targetNamespace' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
#             NAME=$(yq e '.metadata.name' $OUTPUT/bigbang/templates/$COMPONENT/helmrelease.yaml)
#             checkout_component_repo $COMPONENT $GIT_REMOTE $ARG_VERSION
#             ;;
#     esac
    
#     # Template out for the function
#     echo "Apply $COMPONENT to $OUTPUT/$COMPONENT"
#     # rm -rf ./$OUTPUT/$COMPONENT
#     helm upgrade --install $NAME ./upstream/$COMPONENT/chart \
#         -f ./$OUTPUT/$COMPONENT/values-common.yaml \
#         -f ./$OUTPUT/$COMPONENT/values-defaults.yaml \
#         -f ./$OUTPUT/$COMPONENT/values-overlays.yaml \
#         -n $NAMESPACE \
#         --debug
# }


# case "$COMMAND" in
#     up_kind)
#         CLUSTER_NAME=${1:-bb1};
#         shift
#         up_kind $CLUSTER_NAME
#         ;;
    
#     down_kind)
#         CLUSTER_NAME=${1:-bb1};
#         shift
#         down_kind $CLUSTER_NAME
#         ;;

#     up_kind_lb)
#         up_kind_lb
#         ;;
    
#     generate_sops_keys)
#         generate_sops_keys
#         ;;

#     bootstrap)
#         CLUSTER_NAME=${1:-bb1};
#         shift
#         bootstrap $CLUSTER_NAME
#         ;;

#     up_hacks)
#     CLUSTER_NAME=${1:-bb1};
#         shift
#         up_hacks $CLUSTER_NAME
#         ;;

#     up_kc_config)
#         USERNAME=${1:-barney};
#         CLUSTER_NAME=${2:-bb1};
#         shift
#         up_kc_config $USERNAME $CLUSTER_NAME
#         ;;

#     # Old style push based deployments and template-out

#     up_bigbang)
#         CLUSTER_NAME=${1:-bb1};
#         shift
#         up_bigbang $CLUSTER_NAME
#         ;;

#     template_bigbang)
#         OUTPUT=${1:-out};
#         shift
#         template_bigbang $OUTPUT
#         ;;

#     template_bigbang_test_patches)
#         OUTPUT=${1:-out};
#         shift
#         template_bigbang_test_patches $OUTPUT
#         ;;

#     template_component)
#         COMPONENT=${1:-kiali};
#         OUTPUT=${2:-out};
#         shift
#         template_component $OUTPUT $COMPONENT
#         ;;

#     template_wrapper_component)
#         COMPONENT=${1:-openldap};
#         OUTPUT=${2:-out};
#         shift
#         template_wrapper_component $OUTPUT $COMPONENT
#         ;;

#     install_component)
#         COMPONENT=${1:-kiali};
#         OUTPUT=${2:-out};
#         shift
#         install_component $OUTPUT $COMPONENT
#         ;;

#     *)
#         echo "Invalid argument"
#         echo "Usage: $0 {generate_sops_keys|bootstrap} [naam]"
#         exit 1
#         ;;
# esac
