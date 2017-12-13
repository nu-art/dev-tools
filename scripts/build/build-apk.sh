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

tasks=$1
branch=$2
incrementVersionCode=$3
installAndroidPackages=$4
promoteVersion=$5

echo "tasks: ${tasks}"
echo "branch: ${branch}"
echo "incrementVersionCode: ${incrementVersionCode}"
echo "installAndroidPackages: ${installAndroidPackages}"
echo "promoteVersion: ${promoteVersion}"

source ${BASH_SOURCE%/*}/_generic-tools.sh
source ${BASH_SOURCE%/*}/_android-tools.sh

versionFile="../version"
setup ${branch}

modules=$(listGradleAndroidAppsFolders)
echo "modules: ${modules[@]}"

if [ "${installAndroidPackages}" == "true" ]; then
    installPackages
fi

tempModule=(`echo ${modules}`)
if [ "${incrementVersionCode}" == "true" ]; then
    updateVersionCode "${modules[0]}" "${versionFile}"
fi

updateVersionName "${modules[0]}" "${promoteVersion}" "${versionFile}"
build "${modules}" "${tasks}"
updateRepository "${modules}" "${versionFile}"

