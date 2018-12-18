#!/bin/bash

function incrementVersionCode() {
    logInfo "Incrementing version code..."

	local pathToVersionFile=$1
    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

    logInfo "bash gradlew :incrementVersionCode -PpathToVersionFile=${pathToVersionFile}"
    bash gradlew ":incrementVersionCode" "-PpathToVersionFile=${pathToVersionFile}"
    checkExecutionError  "Error incrementing version code"
}

function incrementVersionName() {
    local promoteVersion=$1
	local pathToVersionFile=$2

    if [ "${pathToVersionFile}" == "" ]; then
        pathToVersionFile=./version
    fi

	logInfo "Incrementing ${promoteVersion} version name..."

    logInfo "bash gradlew :incrementVersionName -PpathToVersionFile=${pathToVersionFile} -PpromoteVersion=${promoteVersion}"
    bash gradlew ":incrementVersionName" "-PpathToVersionFile=${pathToVersionFile}" "-PpromoteVersion=${promoteVersion}"

    checkExecutionError  "Error incrementing '${promoteVersion}' version name"
}

function getVersionName() {
    local versionFile=${1}
    local versionName=`cat "${versionFile}" | grep "versionName \".*\"" | sed  -E 's/versionName| |"//g'`
    echo versionName
}

function getVersionCode() {
    local versionFile=${1}
    local versionCode=`cat "${versionFile}" | grep "versionCode .*" | sed  -E 's/versionCode| //g'`
    echo versionCode
}

