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

source ${BASH_SOURCE%/*}/../_core-tools/_source.sh

function incrementVersionCode() {
	local pathToVersionFile=`getVersionFileName ${1}`
    logInfo "Incrementing version code..."

    logInfo "bash gradlew :incrementVersionCode -PpathToVersionFile=${pathToVersionFile}"
    bash gradlew ":incrementVersionCode" "-PpathToVersionFile=${pathToVersionFile}"
    throwError "Error incrementing version code"
}

function incrementVersionName() {
    local promoteVersion=${1}
	local pathToVersionFile=`getVersionFileName ${2}`
	logInfo "Incrementing ${promoteVersion} version name..."

    logInfo "bash gradlew :incrementVersionName -PpathToVersionFile=${pathToVersionFile} -PpromoteVersion=${promoteVersion}"
    bash gradlew ":incrementVersionName" "-PpathToVersionFile=${pathToVersionFile}" "-PpromoteVersion=${promoteVersion}"
    throwError "Error incrementing '${promoteVersion}' version name"
}

function getVersionFileName() {
    local versionFile=${1}

    if [[ ! "${versionFile}" ]]; then
        versionFile=./version
    fi

    echo "${versionFile}"
}

function getVersionName() {
    local versionFile=`getVersionFileName ${1}`
    local versionName=`cat "${versionFile}" | grep "versionName \".*\"" | sed  -E 's/versionName| |"//g'`
    echo ${versionName}
}

function getVersionCode() {
    local versionFile=`getVersionFileName ${1}`
    local versionCode=`cat "${versionFile}" | grep "versionCode .*" | sed  -E 's/versionCode| //g'`
    echo ${versionCode}
}

