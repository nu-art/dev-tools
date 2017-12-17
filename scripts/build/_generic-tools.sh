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
checkVersionAndModulesCorrelation() {
    local modules=$1
    local promoteVersion=$2

    if [ ! "${modules}" == "ALL" ]; then
        if [ "${promoteVersion}" == "Version" ] || [ "${promoteVersion}" == "Major" ]; then
            logInfo "When promoting version using \"${promoteVersion}\" you must include ALL modules"
            exit 1
        fi
    else
        if [ ! "${promoteVersion}" == "Version" ] && [ ! "${promoteVersion}" == "Major" ] && [ ! "${promoteVersion}" == "Minor" ]; then
            logInfo "When promoting version using \"${promoteVersion}\" it is logical to target a group of modules and not ALL"
            exit 1
        fi
    fi
}

setup() {
    local branch=$1

	git checkout "${branch}"
	bash pull-sync.sh
}

build() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "-----------------------------------       Building...        -----------------------------------"

	local modules=(`echo $1`)
	local tasks=(`echo $2`)

    gradleParams=()

    if [ "${TEST_RUN}" == "true" ]; then
        gradleParams=assembleDebug
    else
        for moduleName in "${modules[@]}"; do
            for task in "${tasks[@]}"; do
                gradleParams+="${moduleName}:${task} "
            done
        done
    fi

    logInfo "bash gradlew clean ${gradleParams}"
    bash gradlew clean ${gradleParams}
	checkExecutionError "Building projects"

  	logInfo "-----------------------------------     Build Completed      -----------------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}

updateVersionCode() {
    logInfo "Incrementing version code..."

	local modules=(`logInfo $1`)
	local pathToVersionFile=$2
    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

    gradleParams=()
    for moduleName in "${modules[@]}"; do
        gradleParams+="${moduleName}:incrementVersionCode "
    done

    logInfo "bash gradlew ${gradleParams} -PpathToVersionFile=${pathToVersionFile}"
    bash gradlew ${gradleParams} "-PpathToVersionFile=${pathToVersionFile}"

    checkExecutionError "Incremented Version Code"
}

updateVersionName() {
    local promoteVersion=$1
	local pathToVersionFile=$2

    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

	logInfo "Incrementing ${promoteVersion} version name..."

    logInfo "bash gradlew \"incrementVersionName${promoteVersion}\" -PpathToVersionFile=${pathToVersionFile}"
    bash gradlew ":incrementVersionName" "-PpathToVersionFile=${pathToVersionFile}" "-PpromoteVersion=${promoteVersion}"

	checkExecutionError "Incremented Version Name"
}

updateRepository() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "------------------------------       Update Repositories...        -----------------------------"

    local modules=(${1})
    local pathToVersionFile=$2
    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

    newVersionName=`cat "${pathToVersionFile}" | grep "versionName \".*\"" | sed  -E 's/versionName| |"//g'`
    newVersionCode=`cat "${pathToVersionFile}" | grep "versionCode .*" | sed  -E 's/versionCode| //g'`

    if [ "${newVersionCode}" == "" ]; then
        tag="v${newVersionName}"
        message="Jenkins Build - v${newVersionName}"
    else
        tag="v${newVersionName}-${newVersionCode}"
        message="Jenkins Build - v${newVersionName} (${newVersionCode})"
    fi

    logInfo "Commit push tag: ${tag}, message: ${message}"
    if [ "${TEST_RUN}" == "true" ]; then
        logInfo "This is a test run, will not push changes to repo!!!"

        logInfo "--------------------------------     Repositories Updated!     ---------------------------------"
      	logInfo "------------------------------------------------------------------------------------------------"

        return
    fi

    for module in "${modules[@]}"; do
        pushd ${module} > /dev/null
            gitCommitAndTagAndPush "v${newVersionName}" "Jenkins Build - v${newVersionName}"
        popd > /dev/null
    done

    gitCommitAndTagAndPush "${tag}" "${message}"

    logInfo "--------------------------------     Repositories Updated!     ---------------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}

source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/file-tools.sh
source ${BASH_SOURCE%/*}/../utils/git-tools.sh
