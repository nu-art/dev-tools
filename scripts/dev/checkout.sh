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

source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/../utils/file-tools.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh

paramColor=${BRed}
projectsToIgnore=("dev-tools")

function extractParams() {
    echo
    logInfo "Process params: "
    for paramValue in "${@}"; do
        logDebug "  param: ${paramValue}"

        case "${paramValue}" in
            "--force")
                force="true"
            ;;

            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;
        esac
    done

    echo
    logInfo "Running with params:"
    logDebug "  branchName: ${branchName}"
}

function printUsage() {
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --branch=${branchName}"
    echo -e "  "
    echo
    exit 0
}

function verifyRequirement() {
    missingData=false
    if [ "${branchName}" == "" ]; then
        branchName="${paramColor}branch-name${NoColor}"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        printUsage
    fi
}

extractParams "$@"
verifyRequirement

function processFolder() {
    gitCheckoutBranch ${branchName} ${force}
}

signature
gitCheckoutBranch ${branchName} ${force}
iterateOverFolders "gitListSubmodules" processFolder


