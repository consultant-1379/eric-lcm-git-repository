#! /usr/bin/env bash
#
# COPYRIGHT Ericsson 2023
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


set -eux -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "${SCRIPT_DIR}/../.." && pwd )"

COMMON_PROPERTIES_FILE="$ROOT_DIR/cicd/common-properties.yaml"
FOSS_2PP_DEPS_FILE="$ROOT_DIR/cicd/config/fossa/dependencies.2pp.yaml"
errorMessage=""

if [[ "$GERRIT_CHANGE_OWNER_NAME" == "MXE Jenkins user" ]]
then
    echo "Skipping 2pp version check for automated changesets raised by MXE Jenkins user"
    exit 0
fi

# CBO version check
CBO_VERSION_FROM_RULESET=$(yq '.properties[]| to_entries | .[]| select(.key == "common-base-os-version").value' $COMMON_PROPERTIES_FILE)
CBO_SEMVER_FROM_RULESET=$(echo ${CBO_VERSION_FROM_RULESET} | sed 's/\(.*\)-.*/\1/')

CBO_SEMVER_FROM_2PP_DEPS=$(yq '.2pp_dependencies[] | select(.name == "Common Base OS Micro Image").version' $FOSS_2PP_DEPS_FILE)

if [[ "$CBO_SEMVER_FROM_RULESET" != "$CBO_SEMVER_FROM_2PP_DEPS" ]]; then
    errorMessage+="\nCBO version mismatch between ruleset and 2pp dependencies file. Ruleset version: $CBO_SEMVER_FROM_RULESET, 2pp dependencies version: $CBO_SEMVER_FROM_2PP_DEPS"
fi

# # Stdout redirect version check
# STDOUT_REDIRECT_VERSION_FROM_RULESET=$(yq '.properties[]| to_entries | .[]| select(.key == "stdout-redirect-version").value' $COMMON_PROPERTIES_FILE)

# STDOUT_REDIRECT_VERSION_FROM_2PP_DEPS=$(yq '.2pp_dependencies[] | select(.name == "Stdout Redirect").version' $FOSS_2PP_DEPS_FILE)

# if [[ "$STDOUT_REDIRECT_VERSION_FROM_RULESET" != "$STDOUT_REDIRECT_VERSION_FROM_2PP_DEPS" ]]; then
#     errorMessage+="\nStdout redirect version mismatch between ruleset and 2pp dependencies file. Ruleset version: $STDOUT_REDIRECT_VERSION_FROM_RULESET, 2pp dependencies version: $STDOUT_REDIRECT_VERSION_FROM_2PP_DEPS"
# fi

# if [[ -n "$errorMessage" ]]; then
#     wrappedErrorMessage="The following version mismatches were found between the ruleset and 2pp dependencies file:$errorMessage"
#     echo -e "ERROR: $wrappedErrorMessage"
#     exit 1
# fi