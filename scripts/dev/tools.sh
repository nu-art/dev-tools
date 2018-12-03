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
source ${BASH_SOURCE%/*}/../utils/log-tools.sh

function contains() {
    local found=false
    for i in "${2}"; do
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

    if [ "${indentOutput}" == "false" ]; then
        ${command}
    else
        ${command} | indent "    "
    fi
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
        echo
    done

}