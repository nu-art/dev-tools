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

source ${BASH_SOURCE%/*}/git-tools-core.sh
source ${BASH_SOURCE%/*}/log-tools.sh
source ${BASH_SOURCE%/*}/error-handling.sh
source ${BASH_SOURCE%/*}/tools.sh

fixRemoteTrackingIfNeed() {
    local logFile=${logFile}
    if [ "${logFile}" == "" ]; then
        logError "MUST declare logFile before calling gitCloneIfNeeded" "${resultFile}"
        exit 1
    fi

    onBranch=$(gitGetCurrentBranch)
    branchInfo=`git branch -vv | grep "${onBranch} "`
    upstreamBranch=`sedFunc "${branchInfo}" "s~.\s${onBranch}\s*[a-z0-9]*\s*\[(.*?)\].*~\1~"`

    if [ "${branchInfo}" == "${upstreamBranch}" ]; then
        logWarning "Missing upstream branch... setting to: origin/${onBranch}" "${resultFile}"
        git branch "--set-upstream-to=origin/${onBranch}" "${onBranch}"  2>> "${logFile}" >> "${logFile}"
    else
        logVerbose " - Remote upstream is set to: ${upstreamBranch}"
    fi
}


gitMapSubmodules() {
    local submodule
    local submodules=()

    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ "${line}" =~ "submodule" ]]; then
            submodule=`echo ${line} | sed -E 's/\[submodule "(.*)"\]/\1/'`

            if [ "${submodule}" == "" ]; then
                logError "Error extracting submodule name from line: ${line}" "${resultFile}"
                exit 1
            fi

            submodules[${#submodules[*]}]="${submodule}"
        fi
    done < .gitmodules

    echo "${submodules[@]}"
}

getSubmoduleDetail() {
    local submodule=$1
    if [ "${submodule}" == "" ]; then
        logError "MUST provide a submodule name when calling getSubmoduleDetail" "${resultFile}"
        exit 1
    fi

    gitSubmoduleCommit=
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ "${line}" =~ "submodule" ]]; then
            gitSubmoduleName=`echo ${line} | sed -E 's/\[submodule "(.*)"\]/\1/'`

            if [ "${gitSubmoduleName}" == "" ]; then
                logError "Error extracting submodule name from line: ${line}" "${resultFile}"
                exit 1
            fi

            if [ "${gitSubmoduleName}" != "${submodule}" ]; then
                gitSubmoduleName=
                continue
            fi

            continue
        fi

        if [ "${gitSubmoduleName}" == "" ]; then
            continue
        fi

        if [[ "${line}" =~ "url = " ]]; then
            gitSubmoduleUrl=`echo ${line} | sed -E "s/.*= (.*)$/\1/"`

            if [ "${gitSubmoduleUrl}" == "" ]; then
                logError "Error extracting url from line: ${line}" "${resultFile}"
                exit 1
            fi
        fi

        if [[ "${line}" =~ "branch" ]]; then
            gitSubmoduleBranch=`echo ${line} | sed -E 's/.*= (.*)$/\1/'`

            if [ "${gitSubmoduleBranch}" == "" ]; then
                logError "Error extracting branch from line: ${line}" "${resultFile}"
                exit 1
            fi

            break
        fi
    done < .gitmodules
}

gitCloneIfNeeded() {
    local logFile=${logFile}
    if [ "${logFile}" == "" ]; then
        logError "MUST declare logFile before calling gitCloneIfNeeded" "${resultFile}"
        exit 1
    fi

    local submodule=$1
    if [ "${submodule}" == "" ]; then
        logError "MUST provide a submodule name when calling gitCloneIfNeeded" "${resultFile}"
        exit 1
    fi

    local name=${gitSubmoduleName}
    local branch=${gitSubmoduleBranch}
    local url=${gitSubmoduleUrl}

    logVerbose " -   name: ${name}"
    logVerbose " - branch: ${branch}"
    logVerbose " -    url: ${url}"

    local repoGitFile="${name}/.git"
    if [ -d "${repoGitFile}" ]; then
        return
    fi

    if [ -e "${repoGitFile}" ]; then
        logWarning "Submodule was cloned automatically - re-cloning it"
    else
        logWarning "Submodule is not cloned yet"
    fi

    logDebug "Removing folder from git cache ${submodule}"
    gitRemoveSubmoduleFromCache "${submodule}"  2>> "${logFile}" >> "${logFile}"

    logDebug "deleting empty submodule folder ${submodule}"
    gitDeleteSubmoduleFolder "${submodule}"  2>> "${logFile}" >> "${logFile}"

    logDebug "Cloning repo from: ${url}"
    gitCloneRepoByUrl ${url} 2>> "${logFile}" >> "${logFile}"

    needToUpdateInitSubmodules=true
}

gitPullAndRegisterConflicts() {
    local result="$(gitPullRepo)"
    echo "${result}"
}

gitFetchSetCommitAndRegisteredConflicts() {
    commit=${1}
    git fetch 2>> "${logFile}" >> "${logFile}"
    local result=$(git reset --hard "${commit}")
    echo "${result}"
}

gitStashPopAndRegisterConflicts() {
    stashName=${1}
    logInfo "Applying stash ${stashName}"
    local result=$(gitStashPop "${stashName}")
    echo "${result}"
}