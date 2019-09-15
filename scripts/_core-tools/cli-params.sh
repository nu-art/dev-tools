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


function regexParam() {
    echo `echo "${2}" | sed -E "s/(${1})=(.*)/\2/"`
}

function removePrefix() {
    echo "${1}"
}

function makeItSo() {
    echo "true"
}

function getBashVersion() {
    echo `bash --version | grep version | head -1 | sed -E "s/.* version (.*)\(.*\(.*/\1/"`
}

function installBash() {
    logInfo "Installing bash... this can take some time"
    brew install bash 2> error
    local output=`cat error`
    rm error

    if [[ "${output}" =~ "brew upgrade bash" ]]; then
        brew upgrade bash 2> error
    fi

    if [[ "${output}" =~ "brew: command not found" ]]; then
        logInfo "So... a new computer... ?? installing homebrew ;)"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

function enforceBashVersion() {
    local _minVersion=${1}
    local _bashVersion=`getBashVersion`

    if [[ ! `checkMinVersion ${_bashVersion} ${_minVersion}` ]]; then
        return
    fi

    logError "Found unsupported 'bash' version: ${_bashVersion}"
    logError "Required min version: ${_minVersion}\n ..."
    yesOrNoQuestion "Would you like to install latest 'bash' version [y/n]:" "installBash && logInfo \"Please re-run command..\" && exit 0 " "logError \"Terminating process...\" && exit 2"
}

function printDebugParams() {
    local debug=${1}
    if [[ ! "${debug}" ]]; then
        return
    fi

    local params=("${@}")
    params=("${params[@]}")

    function printParam() {
        if [[ ! "${2}" ]]; then
            return
        fi

        logDebug "--  ${1}: ${2}"
    }

    logInfo "------- DEBUG: PARAMS -------"
    logDebug "--"
    local bashVersion=`getBashVersion`
    printParam "bashVersion" "${bashVersion}"

    for param in "${params[@]}"; do
        local value=("${!param}")
        printParam ${param} "${value}"
    done
    logDebug "--"
    logInfo "----------- DEBUG -----------"
    logVerbose
    sleep 3s
}

function printCommand() {
    local params=("${@}")
    local command=" "
    command="${command}${NoColor}"
#    clear
    logVerbose
    logVerbose
    logVerbose
    logDebug "Command:"
    logVerbose "  ${Cyan}${0}${NoColor}"
    for param in "${params[@]}"; do
        logVerbose "       ${Purple}${param}${NoColor}"
    done
    logVerbose
}