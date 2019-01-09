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
paramColor=${BRed}

projectsToIgnore=("dev-tools")
scope="project"

params=(scope branchName tag)
pids=()

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--tag="*)
                tagName=`echo "${paramValue}" | sed -E "s/--tag=(.*)/\1/"`
            ;;

            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;

            "--all")
                scope="all"
            ;;

            "--project")
                scope="project"
            ;;

            "--origin")
                deleteOrigin="true"
            ;;

            "--debug")
                debug="true"
            ;;
        esac
    done
}

function verifyRequirement() {
    missingData=false
    if [[ ! "${tagName}" ]] || [[ "${tagName}" == "master" ]]; then
        tagName=
        tagNameParam="--tag=${paramColor}tag-name(NOT master)${NoColor}"
    fi

    if [[ ! "${branchName}" ]] || [[ "${branchName}" == "master" ]]; then
        branchName=
        branchNameParam="--branch=${paramColor}branch-name(NOT master)${NoColor}"
    fi

    if [[ ! "${tagName}" ]] && [[ ! "${branchName}" ]]; then
        logVerbose
        logVerbose "   USAGE:"
        logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${tagNameParam} OR ${branchNameParam}"
        logVerbose
        exit 0
    fi
}

extractParams "$@"
verifyRequirement

signature "Delete tag or branch"

function execute() {
    if [[ "${tagName}" ]]; then
        if [[ "${deleteOrigin}" ]]; then
            git push origin :${tagName}
        fi
        git tag --delete ${tagName}
    fi

    if [[ "${branchName}" ]]; then
        if [[ "${deleteOrigin}" ]]; then
            git push origin :${branchName}
        fi
        git branch --delete ${branchName}
    fi
}


function processSubmodule() {
    local mainModule=${1}
    logVerbose
    bannerDebug "Processing: ${mainModule}"
    execute &
    pid=$!
    pids+=(${pid})

    local submodules=(`getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"`)
    for submodule in "${submodules[@]}"; do
        cd ${submodule}
            processSubmodule "${mainModule}/${submodule}"
        cd ..
    done
}

processSubmodule "${runningDir}"
for pid in "${pids[@]}"; do
    wait ${pid}
done
