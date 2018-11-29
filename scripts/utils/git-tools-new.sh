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
GIT_TAG="GIT:"
gitCheckoutBranch() {
    local branchName=${1}
    logInfo "${GIT_TAG} Checking out branch: ${branchName}"
    local output=`git checkout ${branchName}`
    if [[ "${output}" =~ "did not match any file" ]]; then
        logWarning "${GIT_TAG} Could not find branch...  Creating a new branch named: ${branchName}"
        local output=`git checkout -b ${branchName}`
        git push -u origin ${branchName}
    fi
    checkExecutionError
}

gitAddAll() {
    logInfo "${GIT_TAG} git add all"
    git add .
}

gitSaveStash() {
    local stashName=${1}
    logInfo "${GIT_TAG} Stashing changes with message: ${stashName}"
    local result=`git stash save "${stashName}"`
    checkExecutionError
}

gitStashPop() {
    logInfo "${GIT_TAG} Popping last stash"
    git stash pop
}

gitPullRepo() {
    logInfo "${GIT_TAG} Pulling repo from Origin"
    git pull
}


gitRemoveSubmoduleFromCache() {
    local pathToFile=${1}
    logInfo "${GIT_TAG} Removing file from git: ${pathToFile}"
    git rm -rf --cache "${pathToFile}"
    checkExecutionError
}

gitCloneRepoByUrl() {
    local repoUrl=${1}
    local recursive=${recursive}
    logInfo "${GIT_TAG} Cloning repo from url: ${repoUrl}"
    git clone "${repoUrl}" ${recursive}
    checkExecutionError
}


gitClearStash(){
    logInfo "${GIT_TAG} Clearing stash"
    git stash clear
}

gitCommit() {
    local message=$1
    logInfo "${GIT_TAG} Commit with message: ${message}"
    git commit -am "${message}"
}

gitTag() {
    local tag=$1
    local message=$2
    logInfo "${GIT_TAG} creating tag \"${tag}\" with message: ${message}"
    git tag -a ${tag} -am "${message}"
}

gitPush() {
    logInfo "${GIT_TAG} Pushing to origin..."
    git push
}

gitPushTags() {
    logInfo "${GIT_TAG} Pushing tags to origin..."
    git push --tags
}

gitCommitAndTagAndPush() {
    local tag=$1
    local message=$2

    gitCommit "${message}"
    gitTag ${tag} "${message}"
    gitPushTags
    gitPush
}



gitHasRepoChanged() {
    local status=`git status | grep "Changes not staged for commit"`
    if [[ "${status}" =~ "Changes not staged for commit" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

gitGetCurrentBranch() {
    local onBranch=`git status | grep "On branch" | sed -E "s/On branch //"`
    echo "${onBranch}"
}
