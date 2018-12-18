#!/bin/bash
source ${BASH_SOURCE%/*}/../_core-tools/_source.sh
source ${BASH_SOURCE%/*}/version.sh

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

    local gradleParams=""

    for moduleName in "${modules[@]}"; do
        echo ${moduleName}
        for task in "${tasks[@]}"; do
            gradleParams+="${moduleName}:${task} "
        done
    done

    logInfo "bash gradlew clean ${gradleParams}"
    bash gradlew clean ${gradleParams}
	checkExecutionError "Building projects"

  	logInfo "-----------------------------------     Build Completed      -----------------------------------"
  	logInfo "------------------------------------------------------------------------------------------------"
}

function updateRepository() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "------------------------------       Update Repositories...        -----------------------------"

	local modules=(`echo ${1}`)
    local pathToVersionFile=`getVersionFileName ${2}`
    local newVersionName=`getVersionName ${pathToVersionFile}`
    local newVersionCode=`getVersionCode ${pathToVersionFile}`
    local tag=
    local message=

    if [ "${newVersionCode}" == "" ] || [ "${newVersionCode}" == "1" ]; then
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

    build "${modules}" "${tasks}"

    checkExecutionError  "Error while building artifacts"

    updateRepository "${modules}"
    checkExecutionError  "Error while updating repos"
}
