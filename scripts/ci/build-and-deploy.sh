#!/bin/bash
source ${BASH_SOURCE%/*}/../_core-tools/_source.sh

function prepare() {
    local branch=${1}
    git checkout ${branch}
    git submodule update

    cd dev-tools
        git checkout master
        git pull
    cd ..
}

function incrementVersionCode() {
    updateVersionCode "./version"
    checkExecutionError  "Error incrementing version code"
}

function incrementVersionName() {
    local promoteVersion=${1}
    updateVersionName ${promoteVersion} ./version
    checkExecutionError  "Error incrementing '${promoteVersion}' version name"
}

function build() {
	logInfo
  	logInfo "------------------------------------------------------------------------------------------------"
  	logInfo "-----------------------------------       Building...        -----------------------------------"

	local modules=($1)
	local tasks=($2)

    local gradleParams=""

    for moduleName in "${modules[@]}"; do
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

    local modules=(${1})
    local pathToVersionFile=$2
    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

    local newVersionName=`getVersionName ${pathToVersionFile}`
    local newVersionCode=`getVersionCode ${pathToVersionFile}`
    local tag=
    local message=

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
    local modules=(`listGradleGitModulesFolders`)
    build "${modules[@]}" uploadArchives
    checkExecutionError  "Error while building artifacts"

    updateRepository "${modules}" "./version"
    checkExecutionError  "Error while updating repos"
}

function getVersionName() {
    local versionFile=${1}
    local versionName=`cat ${versionFile} | grep "versionName \".*\"" | sed  -E 's/versionName| |"//g'`
    echo versionName
}

function getVersionCode() {
    local versionFile=${1}
    local versionCode=`cat "${versionFile}" | grep "versionCode .*" | sed  -E 's/versionCode| //g'`
    echo versionCode
}

