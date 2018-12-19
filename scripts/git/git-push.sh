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

runningDir=${PWD##*/}
projectsToIgnore=("dev-tools")
params=(branchName scope commitMessage)
scope="changed"

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;

            "--message="*)
                commitMessage=`echo "${paramValue}" | sed -E "s/--message=(.*)/\1/"`
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
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${branchName} ${commitMessage}"
    logVerbose
    exit 0
}

function verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    local missingData=false
    if [ "${branchName}" == "" ]; then
        branchName="${missingParamColor}new-branch-name"
        missingData=true
    fi

    if [ "${commitMessage}" == "" ]; then
        commitMessage="${missingParamColor}Commit message here"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        branchName="--branch=${existingParamColor}${branchName}${NoColor}"
        commitMessage="--message=\"${existingParamColor}${commitMessage}${NoColor}\""
        printUsage
    fi
}


extractParams "$@"
verifyRequirement

signature
printDebugParams ${debug} "${params[@]}"

function processSubmodule() {
    local mainModule=${1}
    logVerbose
    bannerDebug "${mainModule}"
    if [ "${scope}" == "changed" ]; then
        gitCheckoutBranch ${branchName} true
    else
        gitCheckoutBranch ${branchName}
    fi

    local submodules=(`getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"`)

#    echo
#    bannerWarning "changedSubmodules: ${submodules}"

    if [ "${#submodules[@]}" -gt "0" ]; then
        for submoduleName in "${submodules[@]}"; do
            cd ${submoduleName}
                processSubmodule "${mainModule}/${submoduleName}"
            cd ..
        done
        logVerbose
        bannerDebug "${mainModule} - continue"
    fi

    if [[ `hasUntrackedFiles` ]]; then
        gitAddAll
    fi

    if [[ `hasChanged` ]]; then
        gitCommit "${commitMessage}"
    fi

    if [[ `hasCommits` ]]; then
        gitPush ${branchName}
    fi
}

processSubmodule "${runningDir}"