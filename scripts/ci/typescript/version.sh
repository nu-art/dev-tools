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

function getVersionFileName() {
    local versionFile=${1}

    if [[ ! "${versionFile}" ]]; then
        versionFile=package.json
    fi

    if [[ ! -e "${versionFile}" ]]; then
        throwError "No such version file: ${versionFile}" 2
    fi

    echo "${versionFile}"
}

function incrementVersionCode() {
	local pathToVersionFile=`getVersionFileName ${1}`
    throwError "Error incrementing version code"
}

function incrementVersionName() {
    local promoteVersion=${1}
	local pathToVersionFile=`getVersionFileName ${2}`
    throwError "Error incrementing '${promoteVersion}' version name"
}

function getVersionName() {
    local versionFile=`getVersionFileName ${1}`
    local versionName=`cat ${versionFile} | grep '"version":' | head -1 | sed -E "s/.*\"version\".*\"(.*)\",?/\1/"`
    echo ${versionName}
}

function getPackageName() {
    local versionFile=`getVersionFileName ${1}`
    local packageName=`cat ${versionFile} | grep '"name":' | head -1 | sed -E "s/.*\"name\".*\"(.*)\",?/\1/"`
    echo ${packageName}
}

function setVersionName() {
    local newVersionName=${1}
    local versionFile=`getVersionFileName ${2}`

    if [[ `isMacOS` ]]; then
        sed -i '' "s/\"version\": \".*\"/\"version\": \"${newVersionName}\"/g" ${versionFile}
    else
        sed -i "s/\"version\": \".*\"/\"version\": \"${newVersionName}\"/g" ${versionFile}
    fi
}

function getJsonValueForKey() {
    local fileName=${1}
    local key=${2}

    local value=`cat ${fileName} | grep "\"${key}\":" | head -1 | sed -E "s/.*\"${key}\".*\"(.*)\",?/\1/"`
    echo ${value}
}


