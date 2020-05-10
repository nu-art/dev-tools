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

projectsToIgnore=("dev-tools")
source ${BASH_SOURCE%/*}/_core.sh
scope="changed"
runningDir=`getRunningDir`

params=(origin scope branchName)

extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--branch="*)
                branchName=`regexParam "--branch" ${paramValue}`
            ;;

            "-b="*)
                branchName=`regexParam "-b" ${paramValue}`
            ;;

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

            "--origin")
                origin=true
            ;;
        esac
    done
}

extractParams "$@"

signature "Reset hard repo"
printCommand "$@"
printDebugParams ${debug} "${params[@]}"

processSubmodule() {
    local mainModule=${1}
    logVerbose
    bannerDebug "Processing: ${mainModule}"

    gitResetHard ${origin} "${branchName}"
    git clean -f

    local submodules=($(getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"))
    logInfo "submodules: ${submodules[@]}"
    for submodule in "${submodules[@]}"; do
        _cd "${submodule}"
            processSubmodule "${mainModule}/${submodule}"
        _cd..
    done
}

processSubmodule "${runningDir}"
