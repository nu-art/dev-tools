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

function contains() {
    local found=false
    local toIgnore=(${@:2})
    for i in "${toIgnore[@]}"; do
        if [ "${i}" == "${1}" ] ; then
            echo "true"
            return
        fi
    done
    echo "false"
    return
}

function sedFunc() {
    local data=$1
    local pattern=$2
    local command

    if [[ "$(uname -v)" =~ "Darwin" ]]; then
        command="perl -pe"
    else
        command="sed -E"
    fi

    local result=`echo "${data}" | ${command} "${pattern}"`

    echo "${result}"
}

function setDefaultAndroidHome() {
    if [ "${ANDROID_HOME}" != "" ]; then
        return
    fi

    if [[ "$(uname -v)" =~ "Darwin" ]]; then
        local pathToAdb=`which adb`
        if [[ ${pathToAdb} ]]; then
            ANDROID_HOME=${pathToAdb}
        fi
        ANDROID_HOME="/Users/${USER}/Library/Android/sdk"
    else
        ANDROID_HOME="~/Android/sdk"
    fi
}

function indent() {
    sed "s/^/${1}/";
}

function execute() {
    local command=$1
    local message=$2
    local indentOutput=$3


    if [ "${message}" != "" ]; then
        logInfo "${message}"
    else
        logInfo "${command}"
    fi

    if [ "${dryRun}" == "true" ]; then
        return
    fi

    if [ "${message}" != "" ]; then
        logDebug "  ${command}"
    fi

    local errorCode=
    if [ "${indentOutput}" == "false" ]; then
        ${command}
        errorCode=$?
    else
        ${command} | indent "    "
        errorCode=$?
    fi
    logVerbose

    return ${errorCode}
}

function deleteFolder() {
    local folderName=${1}
    logInfo "Deleting folder: ${folderName}"
    rm -rf "${folderName}"
    checkExecutionError
}

function executeProcessor() {
    local processor=${1}
    local dataFetcher=(${2})
    local data=(`${dataFetcher}`)

#    echo "processor: ${processor}"
#    echo "data: ${data[@]}"
    for dataItem in "${data[@]}"; do
        bannerDebug "Processing: ${dataItem}"
        ${processor} ${dataItem}
        logVerbose "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        logVerbose
    done

}

function printDebugParams() {
    local debug=${1}
    if [ ! "${debug}" ]; then
        return
    fi

    local params=("${@}")
    params=("${params[@]:1}")

    function printParam() {
        if [ ! "${2}" ]; then
            return
        fi

        logDebug "--  ${1}: ${2}"
    }

    logInfo "------- DEBUG: PARAMS -------"
    logDebug "--"
    local bashVersion=`bash --version | grep version | head -1 | sed -E "s/.* version (.*)\(.*\(.*/\1/"`
    printParam "bashVersion" "${bashVersion}"

    for param in "${params[@]}"; do
        printParam ${param} "${!param}"
    done
    logDebug "--"
    logInfo "----------- DEBUG -----------"
    logVerbose
}

function printCommand() {
    local params=("${@}")
    local command="  ${Cyan}${0}${Purple}"
    for param in "${params[@]}"; do
        command="${command} ${param}"
    done
    command="${command}${NoColor}"
#    clear
    logVerbose
    logVerbose
    logVerbose
    logDebug "Command:"
    logVerbose "${command}"
    logVerbose
}

printCommand "$@"
