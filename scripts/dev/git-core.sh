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

function gitCheckoutBranch() {
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

function gitAddAll() {
    logInfo "${GIT_TAG} git add all"
    git add .
}

function gitAdd() {
    local toAdd="${1}"
    logInfo "${GIT_TAG} git add ${toAdd}"
    git add "${toAdd}"
}

function gitSaveStash() {
    local stashName=${1}
    logInfo "${GIT_TAG} Stashing changes with message: ${stashName}"
    local result=`git stash save "${stashName}"`
    checkExecutionError
}

function gitStashPop() {
    logInfo "${GIT_TAG} Popping last stash"
    git stash pop
}

function gitPullRepo() {
    logInfo "${GIT_TAG} Pulling repo from Origin"
    git pull
}


function gitRemoveSubmoduleFromCache() {
    local pathToFile=${1}
    logInfo "${GIT_TAG} Removing file from git: ${pathToFile}"
    git rm -rf --cache "${pathToFile}"
    checkExecutionError
}

function gitCloneRepoByUrl() {
    local repoUrl=${1}
    local recursive=${recursive}
    logInfo "${GIT_TAG} Cloning repo from url: ${repoUrl}"
    git clone "${repoUrl}" ${recursive}
    checkExecutionError
}


function gitClearStash(){
    logInfo "${GIT_TAG} Clearing stash"
    git stash clear
}

function gitCommit() {
    local message=$1
    logInfo "${GIT_TAG} Commit with message: ${message}"
    git commit -am "${message}"
}

function gitMerge() {
    local branch=origin/${1}
    logInfo "${GIT_TAG} Merging from ${branch}"
    git merge ${branch}
}

function gitTag() {
    local tag=$1
    local message=$2
    logInfo "${GIT_TAG} creating tag \"${tag}\" with message: ${message}"
    git tag -a ${tag} -am "${message}"
}

function gitPush() {
    logInfo "${GIT_TAG} Pushing to origin..."
    git push
}

function gitPushTags() {
    logInfo "${GIT_TAG} Pushing tags to origin..."
    git push --tags
}

function gitUpdateSubmodules() {
    local submodules=(${@})
    echo ${submodules[@]}
    logInfo "${GIT_TAG} Updating Submodules: ${submodules[@]}"
    git submodule update --init ${submodules[@]}
}

function gitCommitAndTagAndPush() {
    local tag=$1
    local message=$2

    gitCommit "${message}"
    gitTag ${tag} "${message}"
    gitPushTags
    gitPush
}



function gitHasRepoChanged() {
    local status=`git status | grep "Changes not staged for commit"`
    if [[ "${status}" =~ "Changes not staged for commit" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function gitGetCurrentBranch() {
    local onBranch=`git status | grep "On branch" | sed -E "s/On branch //"`
    echo "${onBranch}"
}

function getAllChangedSubmodules() {
    local ALL_REPOS=(`git status | grep -e "modified: .*(" | sed -E "s/.*modified: (.*)\(.*/\1/"`)
    local repos=()
    local toIgnore=(${1})
    for projectName in "${ALL_REPOS[@]}"; do
        if [ `contains ${projectName} "${toIgnore[@]}"` == "true" ]; then
            continue
        fi

        repos+=(${projectName})
    done

    echo "${repos[@]}"
}

function getAllConflictingSubmodules() {
    local ALL_REPOS=(`git status | grep -E "both modified: .*" | sed -E "s/.*both modified: (.*)/\1/"`)
    local repos=()
    local toIgnore=(${1})
    for projectName in "${ALL_REPOS[@]}"; do
        if [ `contains ${projectName} "${toIgnore[@]}"` == "true" ]; then
            continue
        fi

        repos+=(${projectName})
    done

    echo "${repos[@]}"
}

