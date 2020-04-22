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

paramColor=${BRed}
projectsToIgnore=("dev-tools")
params=(githubUsername fromBranch toBranch)

extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--github-username="*)
                githubUsername=`regexParam "--github-username" "${paramValue}"`
            ;;

            "--from="*)
                fromBranch=`regexParam "--from" "${paramValue}"`
            ;;

            "--from-this")
                fromBranch=`gitGetCurrentBranch`
            ;;

            "--to="*)
                toBranch=`regexParam "--to" "${paramValue}"`
            ;;

            "--debug")
                debug="true"
            ;;
        esac
    done
}

printUsage() {
    logVerbose
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromBranch} ${toBranch}"
    logVerbose
    exit 0
}

verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    missingData=
    if [[ ! "${fromBranch}" ]]; then
        fromBranch="--from=${missingParamColor}branch-name${NoColor} OR ${missingParamColor}--from-this${NoColor}"
        missingData=true
    fi

    if [[ ! "${toBranch}" ]]; then
        toBranch="--to=${paramColor}Branch-to-merge-onto${NoColor}"
        missingData=true
    fi

    if [[ "${missingData}" ]]; then
        printUsage
    fi

}
extractParams "$@"
printCommand "$@"
verifyRequirement

currentBranch=`gitGetCurrentBranch`
if [[ "${currentBranch}" != "${fromBranch}" ]]; then
    logError "Main Repo MUST be on branch: ${fromBranch}"
    exit 1
fi

summary=""

processFolder() {
    local submoduleName=${1}
    local currentBranch=`gitGetCurrentBranch`
    if [[ "${currentBranch}" != "${fromBranch}" ]]; then
        logVerbose "repo '${submoduleName}'is not aligned with branch: ${fromBranch}!!"
        return
    fi

    if [[ ! `git status` =~ "Your branch is up to date with 'origin/${fromBranch}'" ]]; then
        logError "repo '${submoduleName}'is not synced with origin!!"
        git status
        exit 1
    fi

    local project=`getGitRepoName`
    throwError "Unable to extract remote project name"

    url="https://github.com/${project}/compare/${toBranch}...${fromBranch}?expand=1"
    echo "URL: ${url}"
    open ${url}
    sleep 2s
    summary="${summary}\nhttps://github.com/${project}/pulls/${githubUsername}"
}

signature "Pull-Request"
printDebugParams ${debug} "${params[@]}"

bannerDebug "Processing: Main Repo"
processFolder "Main Repo"
iterateOverFolders "gitListSubmodules" processFolder

logVerbose "${summary}"
