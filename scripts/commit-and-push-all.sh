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

dateTimeFormatted=`date +%Y-%m-%d--%H-%M-%S`
outputFolder="$(pwd)/build/git-logs"
if [ ! -d "${outputFolder}" ]; then
    mkdir -p "${outputFolder}"
fi

logFile="${outputFolder}/commit-and-push-log-${dateTimeFormatted}.txt"
commitMessage=${1}

if [ "${commitMessage}" == "" ]; then
    logError "Must provide a commit message for all the submodules"
    exit 1
fi

status=`git status | grep "Changes not staged for commit"`
if [[ ! "${status}" =~ "Changes not staged for commit" ]]; then
    logError "No changes on main repo... doing nothing"
    exit 1
fi

function commitAndPushImpl() {
    status=`git status | grep "nothing to commit"`
    if [[ ! "${status}" =~ "nothing to commit" ]]; then
        logDebug "Committing with message: ${commitMessage}"
        git commit -am "${commitMessage}" 2>> "${logFile}" >> "${logFile}"
    fi

    status=`git status | grep "Your branch is up-to-date"`
    if [[ "${status}" =~ "Your branch is up-to-date" ]]; then
        echo "Nothing to push"
        return
    fi

    echo "Pulling..." | tee -a "${logFile}"
    git pull 2>> "${logFile}" >> "${logFile}"

    onBranch=`git status | grep "On branch" | sed -E "s/On branch //"`
    echo "Pushing..." | tee -a "${logFile}"
    git push -u origin ${onBranch} 2>> "${logFile}" >> "${logFile}"
}

function commitAndPushSubmodule() {
    if [[ "${submodule}" == "" ]]; then
        return
    fi

    pushd "${submodule}" 2>> "${logFile}" >> "${logFile}"
        echo | tee -a "${logFile}"
        echo --------------------------------------------------------------------------------------------------- | tee -a "${logFile}"
        echo "Found submodule: '${submodule}'" | tee -a "${logFile}"

        commitAndPushImpl
    popd 2>> "${logFile}" >> "${logFile}"
}

iterateOverFolders "gitMapSubmodules" commitAndPushSubmodule

echo | tee -a "${logFile}"
echo --------------------------------------------------------------------------------------------------- | tee -a "${logFile}"
echo "Main Repository" | tee -a "${logFile}"

commitAndPushImpl
