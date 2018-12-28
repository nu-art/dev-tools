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
    echo `echo "${2}" | sed -E "s/${1}=(.*)/\1/"`
}

function removePrefix() {
    echo "${1}"
}

function makeItSo() {
    echo "true"
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