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

params=(scope tag)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--tag="*)
                tag=`echo "${paramValue}" | sed -E "s/--tag=(.*)/\1/"`
            ;;

            "--all")
                scope="all"
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
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --tag=${tag}"
    echo -e "  "
    echo
    exit 0
}

function verifyRequirement() {
    missingData=false
    if [ "${tag}" == "" ]; then
        tag="${paramColor}tag-name${NoColor}"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        printUsage
    fi
}


extractParams "$@"
verifyRequirement

signature "Delete tag"
function execute() {
    echo git push origin :${tag}
}


function processSubmodule() {
    local mainModule=${1}
    echo
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
