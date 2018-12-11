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
source ${BASH_SOURCE%/*}/../utils/file-tools.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/tools.sh

projectsToIgnore=("dev-tools")
resolution="changed"
grepFilter="HEAD detached|Processing|Your branch|modified|On branch|\^"

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--all")
                resolution="all"
            ;;

            "--project")
                resolution="project"
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

function printDebugParams() {
    if [ ! "${debug}" ]; then
        return
    fi

    function printParam() {
        if [ ! "${2}" ]; then
            return
        fi

        logDebug "--  ${1}: ${2}"
    }

    logInfo "------- DEBUG: PARAMS -------"
    logDebug "--"
    printParam "resolution" ${resolution}
    printParam "debug" ${debug}
    logDebug "--"
    logInfo "----------- DEBUG -----------"
    echo
}


function checkStatus() {
    if [ ! "${grepFilter}" ]; then
        git status
    else
        git status | grep -E "${grepFilter}"
    fi
}

function processSubmodule() {
    local submodule=${1}

    bannerDebug "Processing: ${submodule}"
    cd ${submodule}
        checkStatus
    cd ..
}

extractParams "$@"

signature "Status repo"
printDebugParams

bannerDebug "Processing: Main Repo"
checkStatus

submodules=(`getFolderByResolution ${resolution} "${projectsToIgnore[@]}"`)
for submodule in "${submodules[@]}"; do
    processSubmodule ${submodule}
done