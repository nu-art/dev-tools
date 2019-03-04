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

params=(debug toRepo fromRepo)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--from="*)
                fromRepo=`regexParam "--from" ${paramValue}`
            ;;

            "--to="*)
                toRepo=`regexParam "--to" ${paramValue}`
            ;;

            "--debug")
                debug=true
            ;;
        esac
    done
}

function printUsage() {
    logVerbose
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromRepo} ${toRepo}"
    logVerbose
    exit 0
}

function verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    missingData=
    if [[ ! "${fromRepo}" ]]; then
        fromRepo="${missingParamColor}Repo to clone"
        missingData=true
    fi

    if [[ ! "${toRepo}" ]]; then
        toRepo="${missingParamColor}Repo to mirror${NoColor}"
        missingData=true
    fi

    if [[ "${missingData}" ]]; then
        fromRepo=" --from=${existingParamColor}${fromRepo}${NoColor}"
        toRepo=" --to=${existingParamColor}${toRepo}${NoColor}"

        printUsage
    fi
}

extractParams "$@"
verifyRequirement

signature "Fork Repo"
printCommand "$@"
printDebugParams ${debug} "${params[@]}"

targetName=../temp-repo.git
logInfo "Cloning: ${fromRepo} => ${targetName}"
git clone --bare ${fromRepo} ${targetName}
cd ${targetName}

logInfo "Cloning: ${targetName} => ${toRepo}"
git push --mirror ${toRepo}
cd -
rm -rf ${targetName}
