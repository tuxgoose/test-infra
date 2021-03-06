#!/usr/bin/env bash

# This script generates development artifacts:
# - installer image
# - kyma-installer image
# - kyma-installer-cluster.yaml
# - is-installed.sh
# Yaml files, as well as is-installed.sh script are stored on GCS.

set -e

discoverUnsetVar=false

for var in DOCKER_PUSH_REPOSITORY DOCKER_PUSH_DIRECTORY KYMA_DEVELOPMENT_ARTIFACTS_BUCKET; do
    if [ -z "${!var}" ] ; then
        echo "ERROR: $var is not set"
        discoverUnsetVar=true
    fi
done
if [ "${discoverUnsetVar}" = true ] ; then
    exit 1
fi


readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/library.sh"

function export_variables() {
    COMMIT_ID=$(echo "${PULL_BASE_SHA}" | cut -c1-8)
   if [[ "${BUILD_TYPE}" == "pr" ]]; then
        DOCKER_TAG="PR-${PULL_NUMBER}-${COMMIT_ID}"
        KYMA_INSTALLER_PUSH_DIR="pr/"
        BUCKET_DIR="PR-${PULL_NUMBER}"
    elif [[ "${BUILD_TYPE}" == "master" ]]; then
        DOCKER_TAG="master-${COMMIT_ID}"
        KYMA_INSTALLER_PUSH_DIR="develop/"
        BUCKET_DIR="master-${COMMIT_ID}"
    else
        echo "Not supported build type - ${BUILD_TYPE}"
        exit 1
    fi

   readonly DOCKER_TAG
   readonly KYMA_INSTALLER_PUSH_DIR
   readonly BUCKET_DIR
   readonly KYMA_INSTALLER_VERSION

   export DOCKER_TAG
   export KYMA_INSTALLER_PUSH_DIR
   export BUCKET_DIR
}

init
export_variables

# installer ci-pr, ci-master, kyma-installer ci-pr, ci-master
#   DOCKER_TAG - calculated in export_variables
#   DOCKER_PUSH_DIRECTORY, preset-build-master, preset-build-pr
#   DOCKER_PUSH_REPOSITORY - preset-docker-push-repository
export KYMA_PATH="/home/prow/go/src/github.com/kyma-project/kyma"

buildTarget="ci-master"
if [[ "${BUILD_TYPE}" == "pr" ]]; then
	buildTarget="ci-pr"
fi

shout "Build installer with target ${buildTarget}"
make -C "${KYMA_PATH}/components/installer" ${buildTarget}
shout "Build kyma-installer with target ${buildTarget}"
make -C "${KYMA_PATH}/tools/kyma-installer" ${buildTarget}

shout "Create development artifacts"
# INPUTS:
# - KYMA_INSTALLER_PUSH_DIR
# - KYMA_INSTALLER_VERSION
#  These variables are used to calculate installer version: eu.gcr.io/kyma-project/${KYMA_INSTALLER_PUSH_DIR}kyma-installer:${KYMA_INSTALLER_VERSION}
# - ARTIFACTS_DIR - path to directory where artifacts will be stored
env KYMA_INSTALLER_VERSION="${DOCKER_TAG}" ARTIFACTS_DIR="${ARTIFACTS}" "${KYMA_PATH}/installation/scripts/release-generate-kyma-installer-artifacts.sh"

shout "Content of the local artifacts directory"
ls -la "${ARTIFACTS}"

shout "Switch to a different service account to push to GCS bucket"

export GOOGLE_APPLICATION_CREDENTIALS=/etc/credentials/sa-kyma-artifacts/service-account.json
authenticate

shout "Copy artifacts to ${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/${BUCKET_DIR}"
gsutil cp  "${ARTIFACTS}/kyma-installer-cluster.yaml" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/${BUCKET_DIR}/kyma-installer-cluster.yaml"
gsutil cp  "${KYMA_PATH}/installation/scripts/is-installed.sh" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/${BUCKET_DIR}/is-installed.sh"
gsutil cp  "${KYMA_PATH}/installation/resources/tiller.yaml" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/${BUCKET_DIR}/tiller.yaml"


if [[ "${BUILD_TYPE}" == "master" ]]; then
  shout "Copy artifacts to ${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/master"
  gsutil cp "${ARTIFACTS}/kyma-installer-cluster.yaml" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/master/kyma-installer-cluster.yaml"
  gsutil cp  "${KYMA_PATH}/installation/scripts/is-installed.sh" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/master/is-installed.sh"
  gsutil cp  "${KYMA_PATH}/installation/resources/tiller.yaml" "${KYMA_DEVELOPMENT_ARTIFACTS_BUCKET}/master/tiller.yaml"
fi
