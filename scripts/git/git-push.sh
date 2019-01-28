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
params=(branchName scope commitMessage noPointers)
scope="changed"

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in

            "--branch="*)
                branchName=`regexParam "--branch" ${paramValue}`
            ;;

            "-b="*)
                branchName=`regexParam "-b" ${paramValue}`
            ;;

            "--this")
                branchName=`gitGetCurrentBranch`
            ;;

            "-cb")
                branchName=`gitGetCurrentBranch`
            ;;

            "--no-pointers" | "-np")
                noPointers="true"
            ;;

            "--message="*)
                commitMessage=`regexParam "--message" "${paramValue}"`
            ;;

            "-m="*)
                commitMessage=`regexParam "-m" "${paramValue}"`
            ;;

            "--project")
                scope=`removePrefix "project"`
            ;;

            "--external")
                scope=`removePrefix "external"`
            ;;

            "--debug")
                debug=`makeItSo`
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

    local missingData=
    if [[ ! "${branchName}" ]]; then
        branchName="${missingParamColor}branch-name${NoColor} OR ${missingParamColor}--this${NoColor}"
        missingData=true
    fi

    if [[ ! "${commitMessage}" ]]; then
        commitMessage="${missingParamColor}Commit message here"
        missingData=true
    fi

    if [[ "${missingData}" ]]; then
        branchName="--branch=${existingParamColor}${branchName}${NoColor}"
        commitMessage="--message=\"${existingParamColor}${commitMessage}${NoColor}\""
        printUsage
    fi
}


extractParams "$@"
verifyRequirement

signature
printCommand "$@"
printDebugParams ${debug} "${params[@]}"

function processSubmodule() {
    local submoduleName=${1}
    logVerbose
    bannerDebug "${submoduleName}"
    if [[ "${scope}" == "changed" ]]; then
        gitCheckoutBranch ${branchName} true
    else
        gitCheckoutBranch ${branchName}
    fi

    local submodules=(`getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"`)

#    echo
#    bannerWarning "changedSubmodules: ${submodules}"

    if [[ "${#submodules[@]}" -gt "0" ]]; then
        for _submoduleName in "${submodules[@]}"; do
            cd ${_submoduleName}
                processSubmodule "${submoduleName}/${_submoduleName}"
            cd ..
        done
        logVerbose
        bannerDebug "${submoduleName} - pointers"
        if [[ "${scope}" == "external" ]]; then
            return
        fi

        if [[ "${noPointers}" ]]; then
            return
        fi
    fi


    if [[ `hasConflicts` ]]; then
        logError "Submodule ${submoduleName} has conflicts... Terminating process!!"
        git diff --check
        exit 2
    fi

    if [[ `hasUntrackedFiles` ]]; then
        gitAddAll
    fi

    if [[ `hasChanged` ]]; then
        gitCommit "${commitMessage}"
    fi

    if [[ `hasCommits` ]]; then
        gitPush ${branchName}
        if [[ `hasCommits` ]]; then
            logError "Failed to push... probably need to pull"
            exit 2
        fi
    fi
}

processSubmodule "${runningDir}"