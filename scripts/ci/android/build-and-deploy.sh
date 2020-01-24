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

function prepare() {
    local branch=${1}
    git checkout ${branch}
    git submodule update

    cd dev-tools
        git checkout master
        git pull
    cd ..
}

function build() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "-----------------------------------       Building...        -----------------------------------"

	local modules=(`echo $1`)
	local tasks=(`echo $2`)


    for moduleName in "${modules[@]}"; do
        echo ${moduleName}

        local gradleParams=""
        for task in "${tasks[@]}"; do
            gradleParams+="${moduleName}:${task} "
        done

        bash gradlew ${gradleParams}
	    throwError "Building projects"
    done

    bash gradlew  :closeAndReleaseRepository -i
    throwError "Error deploying to central"

  	logInfo "-----------------------------------     Build Completed      -----------------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}

function updateRepository() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "------------------------------       Update Repositories...        -----------------------------"

	local modules=(`echo ${1}`)
    local newVersionName=`getJsonValueForKey version.json versionName`
    local newVersionCode=`getJsonValueForKey version.json versionCode`
    local tag=
    local message=

    if [[ ! "${newVersionName}" ]]; then
        throwError "could not resolve version" 3
    fi

    if [[ ! "${newVersionCode}" ]] || [[ "${newVersionCode}" == "1" ]]; then
        tag="v${newVersionName}"
        message="Jenkins Build - v${newVersionName}"
    else
        tag="v${newVersionName}-${newVersionCode}"
        message="Jenkins Build - v${newVersionName} (${newVersionCode})"
    fi

    logInfo "TEST_RUN: ${TEST_RUN}"
    logInfo "Commit push tag: ${tag}, message: ${message}"
    logInfo "Commit Message: ${message}"
    logInfo "Tag: ${tag}"

    for module in "${modules[@]}"; do
        pushd ${module} > /dev/null
            git tag -a ${tag} -am "${message}"
            git push origin ${tag}
        popd > /dev/null
    done

    git commit -am "${message}"
    git tag -a "${tag}" -am "${message}"
    git push --tags
    git push

    logInfo "--------------------------------     Repositories Updated!     ---------------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}

function buildDeployPush() {
    local modules=$(listGradleGitModulesFolders)
    local tasks=uploadArchives

    bash gradlew assembleDebug
    throwError "Error compiling project in Debug"

#    bash gradlew test -i
#    throwError "Error running tests"

    build "${modules}" "${tasks}"
    throwError "Error while building artifacts"

    updateRepository "${modules}"
    throwError "Error while updating repos"
}
