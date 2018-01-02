#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash

modules=$1
tasks=$2
branch=$3
installAndroidPackages=$4
promoteVersion=$5
incrementVersionCode=$6
TEST_RUN=$7

echo "modules: ${modules}"
echo "tasks: ${tasks}"
echo "branch: ${branch}"
echo "installAndroidPackages: ${installAndroidPackages}"
echo "promoteVersion: ${promoteVersion}"
echo "incrementVersionCode: ${incrementVersionCode}"
echo "TEST_RUN: ${TEST_RUN}"

source ${BASH_SOURCE%/*}/_generic-tools.sh
source ${BASH_SOURCE%/*}/_android-tools.sh

#checkVersionAndModulesCorrelation "${modules}" "${promoteVersion}"

setup ${branch}

if [ "${modules}" == "ALL" ]; then
    modules=$(listGradleGitModulesFolders)
fi

if [ "${installAndroidPackages}" == "true" ]; then
    installPackages
fi

if [ "${incrementVersionCode}" == "true" ]; then
    updateVersionCode "./version"
fi

updateVersionName "${promoteVersion}" "./version"
build "${modules}" "${tasks}"
updateRepository "${modules}" "./version"
