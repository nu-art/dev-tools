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
# * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash

function throwError() {
	ERROR_CODE=$?

    local errorMessage=${1}
    local errorCode=${2}

    if [[ ! "${errorCode}" ]]; then errorCode=${ERROR_CODE}; fi

    [[ "${errorCode}" == "0" ]] || [[ "${errorCode}" == "1" ]] && return

    throwErrorImpl "${errorMessage}" ${errorCode}
}

function throwWarning() {
	ERROR_CODE=$?

    local errorMessage=${1}
    local errorCode=${2}

    if [[ ! "${errorCode}" ]]; then errorCode=${ERROR_CODE}; fi

    [[ "${errorCode}" == "0" ]] && return

    throwErrorImpl "${errorMessage}" ${errorCode}
}

function throwErrorImpl() {
    local errorMessage=${1}
    local errorCode=${2}

    function fixSource() {
        local file=`echo "${1}" | sed -E "s/(.*)\/[a-zA-Z_-]+\/\.\.\/(.*)/\1\/\2/"`

        if [[ "${file}" == "${1}" ]]; then
            echo "${file}"
            return;
        fi

        fixSource "${file}"
    }

    function printStacktrace() {
        local length=0
        for (( arg=2; arg<${#FUNCNAME[@]}; arg+=1 )); do
            local sourceFile=`fixSource "${BASH_SOURCE[${arg}]}"`
            if (( ${#sourceFile} > length )); then
                length=${#sourceFile}
            fi
        done

        logError "  pwd: `pwd`"
        logError "  Stack:"
        for (( arg=2; arg<${#FUNCNAME[@]}; arg+=1 )); do
            local sourceFile=`fixSource "${BASH_SOURCE[${arg}]}"`
            sourceFile=`printf "%${length}s" "${sourceFile}"`

            local lineNumber="[${BASH_LINENO[${arg}-1]}]"
            lineNumber=`printf "%6s" "${lineNumber}"`

            logError "    ${sourceFile} ${lineNumber} ${FUNCNAME[${arg}]}"
        done
    }

    logError
    logError "  ERROR: ${errorMessage}"
    printStacktrace
    logError
    logError "Exiting with Error code: ${errorCode}"
    echo
    exit ${errorCode}
}
