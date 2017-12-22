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
artifactsIds=()

if [[ -z "${ANDROID_HOME}" ]]; then
    ANDROID_HOME=~/Android/Sdk
fi

addId() {
    local idToAdd=$1
    if [[ ${artifactsIds[@]}  =~ ${idToAdd} ]]; then
        echo already contains id: ${idToAdd}
    else
        artifactsIds+="${idToAdd} "
    fi
}

addConstantVersions() {
    sdkVersion=`cat gradle.properties | grep "COMPILE_SDK=.*" | sed  -E 's/COMPILE_SDK=//g'`
    if [ "${sdkVersion}" != "" ]; then
        addId "platforms;android-${sdkVersion}"
    fi

    buildTool=`cat gradle.properties | grep "TOOLS_VERSION=" | sed  -E 's/TOOLS_VERSION=//'`
    if [ "${buildTool}" != "" ]; then
        addId "build-tools;${buildTool}"
    fi
}

addSDKVersion() {
    sdkVersion=`cat build.gradle | grep "compileSdkVersion .*" | sed  -E 's/compileSdkVersion| //g'`
    addId "platforms;android-${sdkVersion}"
}

addBuildToolVersion() {
    buildTool=`cat build.gradle | grep "buildToolsVersion \".*\"" | sed  -E 's/buildToolsVersion| |"//g'`
    addId "build-tools;${buildTool}"
}

addRepositories() {
    artifactsIds+="extras;google;google_play_services "
    artifactsIds+="extras;android;m2repository "
    artifactsIds+="extras;google;m2repository "
}

installArtifacts() {
    for artifactsId in ${artifactsIds[@]}; do
        echo ${ANDROID_HOME}/tools/bin/sdkmanager "${artifactsId}"
        echo "y " | ${ANDROID_HOME}/tools/bin/sdkmanager "${artifactsId}"
    done

}