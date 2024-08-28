#!/bin/bash
#
# COPYRIGHT Ericsson 2024
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

set -x 
# Script to check if a version update has happened 

cbos_key="common-base-os-version"
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <file_path> <Version string key>"
    exit 1
fi

workspace=$1
file_path=$2
version_key=$3

# Check if a diff exists for the given pattern in the file
if git diff --unified=0 HEAD^ HEAD "$file_path" | grep -q "$version_key"
then
    _3pp_update="true"
else
    _3pp_update="false"
fi

if  git diff --unified=0 HEAD^ HEAD "$file_path" | grep -q "$cbos_key" 
then
    cbos_update="true"
else
    cbos_update="false"
fi

if [ $_3pp_update == "true" ] || [ $cbos_update == "true" ]
then
    echo "true" |tee  $workspace/.bob/var.image-build-check
else
    echo "false" |tee  $workspace/.bob/var.image-build-check
fi

# echo "true" |tee  $workspace/.bob/var.image-build-check