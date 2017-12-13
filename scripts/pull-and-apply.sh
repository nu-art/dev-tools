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

source ${BASH_SOURCE%/*}/utils/file-tools.sh
source ${BASH_SOURCE%/*}/utils/log-tools.sh
source ${BASH_SOURCE%/*}/utils/tools.sh
source ${BASH_SOURCE%/*}/utils/git-tools-core.sh
source ${BASH_SOURCE%/*}/utils/git-tools.sh


setLogFile "build/logs/git" "pull-test"
setLogLevel ${LOG_LEVEL__DEBUG}
resultFile="$(pwd)/build/logs/git/result.sh"

stashName="temp-pull-script"

gitCheckIfHasConflicts() {
    local name=${1}
    local expectedBranch=${2}
    local onBranch=${3}


    if [ "${onBranch}" == "${expectedBranch}" ]; then
        local result=$(git status)
        conflicts=`echo "${result}" | grep "both modified" | sed -E "s/both modified:   (.*)$/Conflict in file: \1/"`
        if [ "${conflicts}" != "" ]; then
            logWarning "Submodule ${name} - Has conflicts" "${resultFile}"
            logWarning "${conflicts}" "${resultFile}"
        else
            logDebug " - Already up to date!"
        fi
        return
    fi
}

gitClearPreviousStash(){
    local moduleName=${1}
    local stashName=${2}

    indices=(`git stash list | grep "${stashName}" | sed -E 's/stash.\{([0-9]+)\}.*/\1/'`)

    stashedCount=${#indices[@]}
    if [ ${stashedCount} -gt 0 ]; then
        logWarning "Submodule ${moduleName} - Found ${stashedCount} old stashes..." "${resultFile}"
        git stash list
    fi

    for ((i=${stashedCount} - 1; i >= 0; i--)) ; do
        git stash drop ${indices[i]}
    done
}

gitCommandWithConflicts() {
    local command=${1}
    local message=${2}
    local resultFile=${3}

    result=$(${command})
    logVerbose "${result}" 2>> "${logFile}" >> "${logFile}"

    logDebug "${message}" "${resultFile}"
    conflicts=`echo "${result}" | grep "CONFLICT" | sed -E "s/CONFLICT.*in (.*)$/Conflict in file: \1/"`
    if [ "${conflicts}" != "" ]; then
        logWarning "Has conflicts" "${resultFile}"
        logWarning "${conflicts}" "${resultFile}"
    fi
}

gitSync() {
    #gitFolders=$(listAllGitFolders)
    gitModules=$(gitMapSubmodules)

    #gitFolders=(${gitFolders//,/ })
    gitModules=(${gitModules//,/ })

    for name in "${gitModules[@]}"; do
        if [ "${name}" == "dev-tools" ]; then
            continue
        fi

        logError " "
        logInfo "----------------------------------- ${name} -----------------------------------"

        if [[ ! -d "${name}" ]]; then
            logInfo "Creating folder: ${name}"
            mkdir "${name}"
        fi

        getSubmoduleDetail ${name}

        gitCloneIfNeeded ${name}

        branch=${gitSubmoduleBranch}
        local currentBranch

        pushDir "${name}"
            currentBranch=$(gitGetCurrentBranch)

            gitCheckIfHasConflicts "${name}" "${branch}" "${currentBranch}"

            gitClearPreviousStash "${name}" "${stashName}"

            local hasModuleChanges=$(gitSaveStash "${stashName}")

            if [ "${hasModuleChanges}" == "true" ]; then
                logDebug " - Saved stash: ${stashName}"

                if [ "${currentBranch}" != "${branch}" ]; then
                    gitStashPop
                    logDebug " - Applied stash: ${stashName}"
                    logError " - Cannot update, submodule '${name}' has changes and need to change branch ${currentBranch} ==> ${branch}" "${resultFile}"
                    return
                fi
            fi
        popDir

        git submodule update --init "${name}" 2>> "${logFile}" >> "${logFile}"

        pushDir "${name}"
            currentBranch=$(gitGetCurrentBranch)

            local commit=`git status | grep "HEAD detached" | sed -E "s/HEAD detached at (.*)/\1/"`
            logVerbose "Expected branch: ${branch}      actual branch: ${currentBranch}"

            if [ "${branch}" != "${currentBranch}" ]; then
                gitCheckoutBranch "${branch}" 2>> "${logFile}" >> "${logFile}"

                logInfo " - Checked out branch ${branch}" "${resultFile}"
            fi

            if [ "${commit}" != "" ]; then
                git reset --hard ${commit}  2>> "${logFile}" >> "${logFile}"

                logInfo " - Reset hard to commit: ${commit}" "${resultFile}"
            fi

            if [ "${hasModuleChanges}" == "true" ]; then
                gitCommandWithConflicts "gitStashPopAndRegisterConflicts \"${stashName}\"" "Submodule '${name}' - Applied stash: ${stashName}" "${resultFile}"
            fi

        popDir
    done
}

gitPullAndSync() {
    local logFile=${logFile}
    if [ "${logFile}" == "" ]; then
        logError "MUST declare logFile before calling gitPullIfNeeded" "${resultFile}"
        exit 1
    fi

    gitClearPreviousStash ${stashName}

    local hasChanges=$(gitSaveStash "${stashName}")
    if [ "${hasChanges}" == "true" ]; then
        logInfo "Saved stash: ${stashName}"
    fi

    logInfo "Pulling main repo..."
    gitCommandWithConflicts "gitPullAndRegisterConflicts" "Pulled main repo" "${resultFile}"

    gitSync

    if [ "${hasChanges}" == "true" ]; then
        gitCommandWithConflicts "gitStashPopAndRegisterConflicts \"${stashName}\"" "Main Repo - Applied stash: ${stashName}" "${resultFile}"
    fi
}

createResultBashFile ${resultFile}

pullDevTools() {
    pushDir dev-tools
        local currentBranch=$(gitGetCurrentBranch)
        if [ "${currentBranch}" != "master" ]; then
            git checkout master
        fi

        git pull
    popDir
}

pullDevTools  2>> "${logFile}" >> "${logFile}"

if [ "${1}" == "" ]; then
    gitPullAndSync
else
    gitSync
fi

bash ${resultFile}
rm ${resultFile}
echo