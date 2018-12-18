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

artifactsIds=()

function installAndroidPackages() {
	echo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "-----------------------------       Installing Packages...        ------------------------------"
	local modules=(${1})


    for module in "${modules[@]}"; do
        pushd "${module}"
            addSDKVersion
            addBuildToolVersion
        popd > /dev/null
    done

    addConstantVersions

    addRepositories
    installArtifacts

   	logInfo "----------------------------     Packages Installation Completed      ---------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}



function removeTrailingChar() {
    local charValueToRemove=${1}
    local string=${2}
    local lastCharValue=`printf "%d\n" \'${string:$i-1:1}`
    if [ "${lastCharValue}" == "${charValueToRemove}" ]; then
        echo "${string:$i1:${#string}-1}"
    else
        echo "${string}"
    fi
}

function addId() {
    local idToAdd=$1
    if [[ ${artifactsIds[@]}  =~ ${idToAdd} ]]; then
        echo already contains id: ${idToAdd}
    else
        artifactsIds+="${idToAdd} "
    fi
}

function addConstantVersions() {
    local sdkVersion=`cat gradle.properties | grep "COMPILE_SDK=.*" | sed  -E 's/COMPILE_SDK=//g'`
    if [ "${sdkVersion}" != "" ]; then
        sdkVersion=`removeTrailingChar 13 ${sdkVersion}`
        addId "platforms;android-${sdkVersion}"
    fi

    local buildTool=`cat gradle.properties | grep "TOOLS_VERSION=" | sed  -E 's/TOOLS_VERSION=//'`
    if [ "${buildTool}" != "" ]; then
        buildTool=`removeTrailingChar 13 ${buildTool}`
        addId "build-tools;${buildTool}"
    fi
}

function addSDKVersion() {
    local sdkVersion=`cat build.gradle | grep "compileSdkVersion .*" | sed  -E 's/compileSdkVersion| //g'`
    sdkVersion=`removeTrailingChar 13 ${sdkVersion}`
    addId "platforms;android-${sdkVersion} "
}

function addBuildToolVersion() {
   local buildTool=`cat build.gradle | grep "buildToolsVersion \".*\"" | sed  -E 's/buildToolsVersion| |"//g'`
    buildTool=`removeTrailingChar 13 ${buildTool}`
    addId "build-tools;${buildTool} "
}

function addRepositories() {
    artifactsIds+="extras;google;google_play_services "
    artifactsIds+="extras;android;m2repository "
    artifactsIds+="extras;google;m2repository "
}

function installArtifacts() {
    for artifactsId in ${artifactsIds[@]}; do
        echo "---${artifactsId}---"
        echo "y " |  ${ANDROID_HOME}/tools/bin/sdkmanager "${artifactsId}"
    done
}