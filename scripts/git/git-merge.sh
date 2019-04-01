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

source ${BASH_SOURCE%/*}/_core.sh

runningDir=`getRunningDir`
projectsToIgnore=("dev-tools")
params=(fromBranch toBranch)
scope="conflict"

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--from="*)
                fromBranch=`echo "${paramValue}" | sed -E "s/--from=(.*)/\1/"`
            ;;

            "--to="*)
                toBranch=`echo "${paramValue}" | sed -E "s/--to=(.*)/\1/"`
            ;;

            "--to-this")
                toBranch=`gitGetCurrentBranch`
            ;;

            "--project")
                scope="project"
            ;;

            "--debug")
                debug="true"
            ;;
        esac
    done
}

function printUsage() {
    logVerbose
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromBranch} ${toBranch}"
    logVerbose
    exit 0
}

function verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    missingData=
    if [[ ! "${fromBranch}" ]]; then
        fromBranch="${missingParamColor}Branch-to-be-merged-from"
        missingData=true
    fi

    if [[ ! "${toBranch}" ]]; then
        toBranch="${missingParamColor}branch-name${NoColor} OR ${missingParamColor}--to-this${NoColor}"
        missingData=true
    fi

    if [[ "${missingData}" ]]; then
        fromBranch=" --from=${existingParamColor}${fromBranch}${NoColor}"
        toBranch=" --to=${existingParamColor}${toBranch}${NoColor}"

        printUsage
    fi
}

extractParams "$@"
verifyRequirement

signature
printCommand "$@"
printDebugParams ${debug} "${params[@]}"


function execute() {
    currentBranch=`gitGetCurrentBranch`
    if [[  "${currentBranch}" != "${toBranch}" ]]; then
        logWarning "Will not merge... expected branch: ${toBranch} but found: ${currentBranch}"
        return
    fi

    gitMerge ${fromBranch}
}

function processSubmodule() {
    local mainModule=${1}
    bannerDebug "${mainModule}"

    execute

    local submodules=(`getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"`)
#    echo
#    echo "conflictingSubmodules: ${submodules[@]}"

    for submodule in "${submodules[@]}"; do
        cd ${submodule}
            processSubmodule "${mainModule}/${submodule}"
        cd ..
    done

    local submodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
#    echo
#    echo "changedSubmodules: ${submodules[@]}"
    gitUpdateSubmodules "${submodules[@]}"
}


processSubmodule "${runningDir}"