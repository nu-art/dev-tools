#!/bin/bash

source ${BASH_SOURCE%/*}/../_core-tools/_source.sh

function incrementVersionCode() {
	local pathToVersionFile=`getVersionFileName ${1}`
    logInfo "Incrementing version code..."

    logInfo "bash gradlew :incrementVersionCode -PpathToVersionFile=${pathToVersionFile}"
    bash gradlew ":incrementVersionCode" "-PpathToVersionFile=${pathToVersionFile}"
    checkExecutionError  "Error incrementing version code"
}

function incrementVersionName() {
    local promoteVersion=${1}
	local pathToVersionFile=`getVersionFileName ${2}`
	logInfo "Incrementing ${promoteVersion} version name..."

    logInfo "bash gradlew :incrementVersionName -PpathToVersionFile=${pathToVersionFile} -PpromoteVersion=${promoteVersion}"
    bash gradlew ":incrementVersionName" "-PpathToVersionFile=${pathToVersionFile}" "-PpromoteVersion=${promoteVersion}"
    checkExecutionError  "Error incrementing '${promoteVersion}' version name"
}

function getVersionFileName() {
    local versionFile=${1}

    if [ "${versionFile}" == "" ]; then
        versionFile=./version
    fi

    echo "${versionFile}"
}

function getVersionName() {
    local versionFile=`getVersionFileName ${1}`
    local versionName=`cat "${versionFile}" | grep "versionName \".*\"" | sed  -E 's/versionName| |"//g'`
    echo versionName
}

function getVersionCode() {
    local versionFile=`getVersionFileName ${1}`
    local versionCode=`cat "${versionFile}" | grep "versionCode .*" | sed  -E 's/versionCode| //g'`
    echo versionCode
}

