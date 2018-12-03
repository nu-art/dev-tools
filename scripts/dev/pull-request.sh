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

paramColor=${BRed}
projectsToIgnore=("dev-tools")

function extractParams() {
    echo
    logInfo "Process params: "
    for paramValue in "${@}"; do
        logDebug "  param: ${paramValue}"
        case "${paramValue}" in
            "--github-username="*)
                githubUsername=`echo "${paramValue}" | sed -E "s/--github-username=(.*)/\1/"`
            ;;

            "--from="*)
                fromBranch=`echo "${paramValue}" | sed -E "s/--from=(.*)/\1/"`
            ;;

            "--to="*)
                toBranch=`echo "${paramValue}" | sed -E "s/--to=(.*)/\1/"`
            ;;
        esac
    done

    echo
    logInfo "Running with params:"
    logDebug "  fromBranch: ${fromBranch}"
    logDebug "  toBranch: ${toBranch}"
}

function printUsage() {
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --from=${fromBranch} --to=${toBranch}"
    echo -e "  "
    echo
    exit 0
}

function verifyRequirement() {
    missingData=false
    if [ "${fromBranch}" == "" ]; then
        fromBranch="${paramColor}Branch-to-be-merged-from${NoColor}"
        missingData=true
    fi

    if [ "${toBranch}" == "" ]; then
        toBranch="${paramColor}Branch-to-merge-onto${NoColor}"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        printUsage
    fi

}

extractParams "$@"
verifyRequirement

banner "Main Repo"
currentBranch=`gitGetCurrentBranch`
echo "currentBranch: '${currentBranch}'"
echo "fromBranch:    '${fromBranch}'"

if [ "${currentBranch}" != "${fromBranch}" ]; then
    logError "Main Repo MUST be on branch: ${fromBranch}"
    exit 1
fi

summary=""

function processFolder() {
    local submoduleName=${1}
    local currentBranch=`gitGetCurrentBranch`
    if [ "${currentBranch}" != "${fromBranch}" ]; then
        logVerbose "repo '${submoduleName}'is not aligned with branch: ${fromBranch}!!"
        return
    fi

    if [[ ! `git status` =~ "Your branch is up to date with 'origin/${fromBranch}'" ]]; then
        logError "repo '${submoduleName}'is not synced with origin!!"
        git status
        exit 1
    fi

    project=`git remote -v | head -1 | perl -pe "s/.*:(.*?)(:?.git| ).*/\1/"`
    checkExecutionError "Unable to extract remote project name"

    url="https://github.com/${project}/compare/${toBranch}...${fromBranch}?expand=1"
    echo "URL: ${url}"
    open ${url}
#    checkExecutionError "Error launching browser with url: ${url}"

    summary="${summary}\nhttps://github.com/${project}/pulls/${githubUsername}"
}

processFolder
iterateOverFolders "gitListSubmodules" processFolder

echo -e "${summary}"
