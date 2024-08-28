#! /usr/bin/env bash
#
# COPYRIGHT Ericsson 2022
#
#
#
# The copyright to the computer program(s) herein is the property of
#
# Ericsson Inc. The programs may be used and/or copied only with written
#
# permission from Ericsson Inc. or in accordance with the terms and
#
# conditions stipulated in the agreement/contract under which the
#
# program(s) have been supplied.
#

set -ux -o pipefail;

# workspace="$1"
IMAGE_FULL_NAME_PREFIX="$1"
CHANGED_FILES_BOBVAR_FILE="$2"

# Absolute filepath to this script
case "$(uname -s)" in
Darwin*) SCRIPT=$(greadlink -f $0) ;;
*) SCRIPT=$(readlink -f $0) ;;
esac

# Location of parent dir
BASE_DIR=$(dirname $SCRIPT)
REPOROOT=$(dirname $(dirname $BASE_DIR))
PRODUCT_INFO_FILE="helm/eric-lcm-git-repository/eric-product-info.yaml"
FOSSA_CONFIG_DIR="$REPOROOT/cicd/config/fossa"
FRAGMENTS_DIR="$REPOROOT/cicd/config/fragments"
FOSSA_CONFIG_DIR="cicd/config/fossa"
FRAGMENTS_DIR="cicd/config/fragments"
COMMON_PROPERTIES_FILE="cicd/common-properties.yaml"

# derive 
imageRepo=$(echo $IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $2}')
imageNamePrefix=$(echo $IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $3}' | awk -F: '{print $1}')
imageVersion=$(echo $IMAGE_FULL_NAME_PREFIX | awk -F/ '{print $3}' | awk -F: '{print $2}')

imageIds=( "gitea" )

filesToSync=()

for imageId in "${imageIds[@]}"
do 
    echo "Set ${imageNamePrefix}-${imageId} docker repo to ${imageRepo}"
    image=$imageNamePrefix-${imageId} repoPath=$imageRepo yq e -i '.images[env(image)].repoPath = env(repoPath)' "$PRODUCT_INFO_FILE"
    echo "Set ${imageNamePrefix}-${imageId} docker image version to ${imageVersion}"
    image=$imageNamePrefix-${imageId} tag=$imageVersion yq e -i '.images[env(image)].tag = env(tag)' "$PRODUCT_INFO_FILE"

done 

changedFiles=($PRODUCT_INFO_FILE)


# Add new line after license header. It is lost due to yq manipulation
sed -i '/^productName:.*/i \ ' "$PRODUCT_INFO_FILE"

printf '%s\n' "${changedFiles[@]}" > $CHANGED_FILES_BOBVAR_FILE
# compare stdout-redirect version
# BUILD_REPO_STDOUT_REDIRECT_VERSION=$(yq '.properties[]| to_entries | .[]| select(.key == "stdout-redirect-version").value' $BUILD_RULESET_FILE)
# SERVICE_REPO_STDOUT_REDIRECT_VERSION=$(yq '.properties[]| to_entries | .[]| select(.key == "stdout-redirect-version").value' "${ML_PIPELINE_PATH}/$COMMON_PROPERTIES_FILE")

# if [ "$BUILD_REPO_STDOUT_REDIRECT_VERSION" != "$SERVICE_REPO_STDOUT_REDIRECT_VERSION" ]; then
#     echo "stdout-redirect-version is different in build repo and service repo"
#     echo "stdout-redirect-version in build repo: $BUILD_REPO_STDOUT_REDIRECT_VERSION"
#     echo "stdout-redirect-version in service repo: $SERVICE_REPO_STDOUT_REDIRECT_VERSION"
#     echo "Update stdout-redirect-version in service repo"
#     sed -i "s/stdout-redirect-version: $SERVICE_REPO_STDOUT_REDIRECT_VERSION/stdout-redirect-version: $BUILD_REPO_STDOUT_REDIRECT_VERSION/g" "$COMMON_PROPERTIES_FILE"
#     echo "Updated stdout-redirect-version in common-properties"
# fi

