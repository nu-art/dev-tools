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
    local array=(${@:2})
    for i in "${array[@]}"; do
        if [[ "${i}" == "${1}" ]] ; then
            echo "true"
            return
        fi
    done
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
    if [[ "${ANDROID_HOME}" ]]; then
        return
    fi

    if [[ `isMacOS` ]]; then
        if [[ ! -e "/Users/${USER}/Library/Android/sdk" ]]; then
            local pathToAdb=`which adb`
            if [[ ${pathToAdb} ]]; then
                ANDROID_HOME=`echo ${pathToAdb} | sed -E "s/^(.*)\/platform-tools\/adb$/\1/"`
                return
            fi
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


    if [[ "${message}" ]]; then
        logInfo "${message}"
    else
        logInfo "${command}"
    fi

    if [[ "${message}" ]]; then
        logDebug "  ${command}"
    fi

    local errorCode=
    if [[ "${indentOutput}" == "false" ]]; then
        ${command}
    else
        ${command} | indent "    "
    fi

    logVerbose
    throwError "${message}"

    return ${errorCode}
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

function yesOrNoQuestion() {
    local message=${1}
    local toExecuteYes=${2}
    local toExecuteNo=${3}

    logWarning "${message}"
    read  -n 1 -p "" response

    logVerbose
    case "$response" in
        [yY])
                eval ${toExecuteYes}
                throwError "Error executing: ${toExecuteYes}"
            ;;
        [nN])
                eval ${toExecuteNo}
                throwError "Error executing: ${toExecuteNo}"
            ;;
        *)
                logError "Canceling..."
                exit 2
            ;;
    esac
}

function choicePrintOptions() {
    local message=${1}
    local options=("${@}")
    options=("${options[@]:1}")

    for (( arg=0; arg<${#options[@]}; arg+=1 )); do
        local option="${arg}. ${options[${arg}]}"
        logDebug "   ${option}"
    done
    logVerbose
    logWarning "   ${message}"
    logVerbose
}

function choiceWaitForInput() {
    local options=("${@}")

    response=-1
    while (( "${response}" < 0 || ${response} >= ${#options[@]} )); do
        read  -n 1 -p "" response
        response=`isNumeric "${response}" "-1"`
    done

    echo "${options[${response}]}"
}

function isNumeric() {
    local re=''
    if [[ ! "${1}" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]] ; then
       echo "${2}"
       return
    fi

    echo "${1}"
}

function isMacOS() {
    if [[ "$(uname -v)" =~ "Darwin" ]]; then echo "true"; else echo; fi
}