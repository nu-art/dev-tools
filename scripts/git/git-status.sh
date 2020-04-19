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
scope="changed"
grepFilter="HEAD detached|you are still merging|Processing|Your branch|modified|On branch|\^"

params=(scope grepFilter)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--project" | "-p")
                scope="project"
            ;;

            "--all" | "-a")
                scope="all"
            ;;

            "--external" | "-e")
                scope="external"
            ;;

            "--debug")
                debug="true"
            ;;

            "--no-filter")
                grepFilter=
            ;;
        esac
    done
}

extractParams "$@"

signature "Status repo"
printCommand "$@"
printDebugParams ${debug} "${params[@]}"

function execute() {
    if [[ ! "${grepFilter}" ]]; then
        git status
    else
        git status | grep -E "${grepFilter}"
    fi
}


function processSubmodule() {
    local mainModule=${1}
    logVerbose
    bannerDebug "Processing: ${mainModule}"
    execute

    local submodules=(`getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"`)
    for submodule in "${submodules[@]}"; do
        cd ${submodule}
            processSubmodule "${mainModule}/${submodule}"
        cd ..
    done
}

processSubmodule "${runningDir}"

