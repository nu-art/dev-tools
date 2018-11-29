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

gitCheckoutBranch() {
    local branchName=${1}
    git checkout "${branchName}"
    checkExecutionError
}

gitSaveStash() {
    local stashName=${1}

    local result=`git stash save "${stashName}"`
    echo "${result}" 2>> "${logFile}" >> "${logFile}"
    checkExecutionError
    if [[ "${result}" =~ "No local changes to save" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

gitStashPop() {
    git stash pop
}

gitPullRepo() {
    git pull
}

gitDeleteSubmoduleFolder() {
    rm -rf "${1}"
    checkExecutionError
}

gitRemoveSubmoduleFromCache() {
    git rm -rf --cache "${1}"
    checkExecutionError
}

gitCloneRepoByUrl() {
    git clone "${1}"
    checkExecutionError
}

gitHasRepoChanged() {
    local status=`git status | grep "Changes not staged for commit"`
    if [[ "${status}" =~ "Changes not staged for commit" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

gitClearStash(){
    git stash clear
}

gitGetCurrentBranch() {
    local onBranch=`git status | grep "On branch" | sed -E "s/On branch //"`
    echo "${onBranch}"
}

gitCommitAndTagAndPush() {
    tag=$1
    message=$2

    logInfo "Commit Message: ${message}"
    logInfo "Tag: ${tag}"

    git commit -am "${message}"
    git tag -a "${tag}" -am "${message}"
    git push --tags
    git push
}