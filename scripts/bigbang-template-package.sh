#!/bin/bash
set -euxo pipefail

BASE=$(dirname $(dirname $(realpath $0)))
PACKAGE=${1:-opencode};
OUTPUT=${2:-$BASE/out/$PACKAGE};

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
    local PACKAGE=${1}
    local GIT_REMOTE=${2}
    local ARG_VERSION=${3}
    local REPO_PATH=$BASE/upstream/${PACKAGE}
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
# opencode-values
#     cat ./$OUTPUT/bigbang/templates/wrapper/values.yaml | yq e '.stringData."values.yaml"' > ./$OUTPUT/wrapper/values.yaml
cat $OUTPUT/bigbang/templates/package/values.yaml | yq e 'select(.kind == "Secret" and .metadata.name == "'$PACKAGE'-values") | .stringData."common.yaml"' > $OUTPUT/package-common.yaml
cat $OUTPUT/bigbang/templates/package/values.yaml | yq e 'select(.kind == "Secret" and .metadata.name == "'$PACKAGE'-values") | .stringData."values.yaml"' > $OUTPUT/package-values.yaml

# Fetch the upstream repo for the package; can be a helmrepo or gitrepo
# if $BASE/environments/dev/config.yaml | yq '.packages.$PACKAGE.sourceType' == 'git' ...
# GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/package/gitrepository.yaml)
# ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/package/gitrepository.yaml)
# else helmrepo

# Fetch the helm repo name from the config
REPO_NAME=$(yq e 'select(.kind == "HelmRelease" and .metadata.name == "'$PACKAGE'") | .spec.chart.spec.sourceRef.name' $OUTPUT/bigbang/templates/package/helmrelease.yaml)
CHART_NAME=$(yq e 'select(.kind == "HelmRelease" and .metadata.name == "'$PACKAGE'") | .spec.chart.spec.chart' $OUTPUT/bigbang/templates/package/helmrelease.yaml)
CHART_TAG=$(yq e 'select(.kind == "HelmRelease" and .metadata.name == "'$PACKAGE'") | .spec.chart.spec.version' $OUTPUT/bigbang/templates/package/helmrelease.yaml)
NAMESPACE=$(yq e 'select(.kind == "HelmRelease" and .metadata.name == "'$PACKAGE'") | .spec.targetNamespace' $OUTPUT/bigbang/templates/package/helmrelease.yaml)
# Locate the helmrepo
HELM_REPO_URL=$(yq e 'select(.kind == "HelmRepository" and .metadata.name == "'$REPO_NAME'") | .spec.url' $OUTPUT/bigbang/templates/helm-repository/helmrepo.yaml)
# Fetch the repo and untar for easy debugging
mkdir -p $OUTPUT/charts
rm -rf $OUTPUT/charts/$CHART_NAME
helm pull $HELM_REPO_URL/$CHART_NAME --version $CHART_TAG --destination $OUTPUT/charts --untar
# /home/pbox/projects/bigbang1/out/opencode/charts/kubeopencode

# Template out for the component
echo "Templating $PACKAGE to $OUTPUT"
helm template $OUTPUT/charts/$CHART_NAME \
    -f $OUTPUT/package-common.yaml \
    -f $OUTPUT/package-values.yaml \
    -n $NAMESPACE \
    --output-dir $OUTPUT

# if wrapper...
cat $OUTPUT/bigbang/templates/wrapper/values.yaml | yq e 'select(.kind == "Secret" and .metadata.name == "'$PACKAGE'-wrapper-values") | .stringData."values.yaml"' > $OUTPUT/package-wrapper-values.yaml

# Setup clone for the wrapper upstream (from GitRepository resource)
# Extract remote from the GitRepository resource
GIT_REMOTE=$(yq e '.spec.url' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
ARG_VERSION=$(yq e '.spec.ref.tag' $OUTPUT/bigbang/templates/wrapper/gitrepository.yaml)
NAMESPACE=$(yq e 'select(.kind == "HelmRelease" and .metadata.name == "'$PACKAGE'-wrapper") | .spec.targetNamespace' $OUTPUT/bigbang/templates/wrapper/helmrelease.yaml)
checkout_component_repo wrapper $GIT_REMOTE $ARG_VERSION

# Template out for the wrapper
echo "Templating wrapper ($PACKAGE) to $OUTPUT/wrapper"
helm template ./upstream/wrapper/chart \
    -f $OUTPUT/package-wrapper-values.yaml \
    -n $NAMESPACE \
    --output-dir $OUTPUT
