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

dateTimeFormatted=`date +%Y-%m-%d--%H-%M-%S`
outputFolder="$(pwd)/build/git-logs"
if [ ! -d "${outputFolder}" ]; then
    mkdir -p "${outputFolder}"
fi
logFile="${outputFolder}/commit-and-push-log-${dateTimeFormatted}.txt"

remote=`git remote -v | grep push`
if [[ "${remote}" =~ "ssh://" ]]; then
#    echo "checking userName: ${line}"
    sshUserName=`echo "${remote}" | sed -E "s/orig.*ssh:\/\/(.*)@.*/\1/"`
    echo "sshUserName: ${sshUserName}"
fi

function fixTrackingInfoIfNeed() {
    onBranch=`git status | grep "On branch" | sed -E "s/On branch //"`
    branchInfo=`git branch -vv | grep "${onBranch} "`
    if [[ "$(uname -v)" =~ "Darwin" ]]; then
        upstreamBranch=`echo "${branchInfo}" | perl -pe "s~.\s${onBranch}\s*[a-z0-9]*\s*\[(.*?)\].*~\1~"`
    else
        upstreamBranch=`echo "${branchInfo}" | sed -E "s~.\s${onBranch}\s*[a-z0-9]*\s*\[(.*?)\].*~\1~"`
    fi

#    echo "onBranch: ${onBranch}"
#    echo "branchInfo: ${branchInfo}"
#    echo "upstreamBranch: ${upstreamBranch}"

    if [ "${branchInfo}" == "${upstreamBranch}" ]; then
        echo "Could not find a branch upstream info" | tee -a "${logFile}"
        echo "Setting to origin/${onBranch}" | tee -a "${logFile}"

        git branch "--set-upstream-to=origin/${onBranch}" "${onBranch}"  2>> "${logFile}" >> "${logFile}"
    fi
}

updateToMainRepo=$1
needToUpdateInitSubmodules=
function pullSubmoduleImpl() {
    echo  | tee -a "${logFile}"
    echo --------------------------------------------------------------------------------------------------- | tee -a "${logFile}"
    echo "Found submodule: ${submodule} from: ${url}"
    echo "Commit Hash: ${commit} on Branch: ${branch}" | tee -a "${logFile}"

    if [ ! -e ".git" ]; then
        echo "THIS SUBMODULE IS NOT CLONED YET..." | tee -a "${logFile}"
        popd 2>> "${logFile}" >> "${logFile}"

        echo "Removing folder from git cache ${submodule}" | tee -a "${logFile}"
        git rm -rf --cache "${submodule}"  2>> "${logFile}" >> "${logFile}"

        echo "deleting empty submodule folder ${submodule}" | tee -a "${logFile}"
        rm -rf "${submodule}"  2>> "${logFile}" >> "${logFile}"

        echo "Attempt to clone it now from: ${url}" | tee -a "${logFile}"
        git clone "${url}" 2>> "${logFile}" >> "${logFile}"

        needToUpdateInitSubmodules=true

        pushd "${submodule}" 2>> "${logFile}" >> "${logFile}"
    fi

    if [ ! -d ".git" ]; then
        echo "COULD NOT CLONE THE REPO!!!" | tee -a "${logFile}"
        return
    fi

    status=`git status | grep "Changes not staged for commit"`

    fixTrackingInfoIfNeed
    if [ "${commit:0:1}" == " " ] && [[ "${onBranch}" =~ "${branch}" ]]; then
        echo "Submodule is up to date with main repo... will not pull" | tee -a "${logFile}"
        return
    fi

    if [[ "${status}" =~ "Changes not staged for commit" ]] && [[ ! "${onBranch}" =~ "${branch}" ]]; then
        echo "Will not update submodule:"
        echo " -- Submodule has changes."
        echo " -- Need to change branch ${onBranch} ==> ${onBranch}" | tee -a "${logFile}"
        return
    fi

    if [[ ! "${onBranch}" =~ "${branch}" ]]; then
        echo "Checking out branch..." | tee -a "${logFile}"
        git checkout ${branch} 2>> "${logFile}" >> "${logFile}"
        fixTrackingInfoIfNeed

    git stash clear
    elif [[ "${status}" =~ "Changes not staged for commit" ]]; then
        echo "Stash save..." | tee -a "${logFile}"
        git stash save "temp-pull-script" 2>> "${logFile}" >> "${logFile}"
    fi

    echo "Pulling..." | tee -a "${logFile}"
    git pull 2>> "${logFile}" >> "${logFile}"


    if [ "${updateToMainRepo}" == "true" ]; then
        echo "Reset hard to commit hash..." | tee -a "${logFile}"
        git reset --hard ${commit} 2>> "${logFile}" >> "${logFile}"

    fi

    if [[ "${status}" =~ "Changes not staged for commit" ]]; then
        echo "Stash apply..." | tee -a "${logFile}"
        git stash pop 2>> "${logFile}" >> "${logFile}"
    fi
}

function pullSubmodule() {
    if [[ "${submodule}" == "" ]]; then
        return
    fi

    if [[ ! -d "${submodule}" ]]; then
        mkdir "${submodule}"
    fi

    pushd "${submodule}" 2>> "${logFile}" >> "${logFile}"
        pullSubmoduleImpl
    popd 2>> "${logFile}" >> "${logFile}"
    submodule=
}

echo "On Main Repo"
mainRepoStatus=`git status | grep "Changes not staged for commit"`
git stash clear

if [[ "${mainRepoStatus}" =~ "Changes not staged for commit" ]]; then
    echo "Stash save..." | tee -a "${logFile}"
    git stash save "temp-pull-script" 2>> "${logFile}" >> "${logFile}"
fi

echo "Pulling..." | tee -a "${logFile}"
git pull 2>> "${logFile}" >> "${logFile}"
echo "Done..." | tee -a "${logFile}"

submodule=
commit=
while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ "${line}" =~ "branch" ]]; then
#        echo "checking branch: ${line}"
        branch=`echo ${line} | sed -E 's/.*= (.*)$/\1/'`
#        echo "end"
    fi

    if [[ "${line}" =~ "url = " ]]; then
#        echo "checking url: ${line}"
        url=`echo ${line} | sed -E "s/.*= (.*)$/\1/"`
#        echo "end"
    fi

    if [[ "${line}" =~ "submodule" ]]; then
        pullSubmodule
#        echo "checking submodule: ${line}"
        submodule=`echo ${line} | sed -E 's/\[submodule "(.*)"\]/\1/'`
#        echo "end"

#        echo "checking commit"
        if [[ "$(uname -v)" =~ "Darwin" ]]; then
            commit=`git submodule status | grep -E "${submodule}($| )" | perl -pe 's/([ \+-][a-z0-9]*?)\s.*/\1/'`
        else
            commit=`git submodule status | grep -E "${submodule}($| )" | sed -E 's/([ \+-][a-z0-9]*?)\s.*/\1/'`
        fi
#        echo "end"

#        echo "checking commit for update"
        if [ "${commit:0:1}" == "-" ]; then
            needToUpdateInitSubmodules=true
        fi
#        echo "end"
    fi
done < .gitmodules

pullSubmodule

echo  | tee -a "${logFile}"
echo --------------------------------------------------------------------------------------------------- | tee -a "${logFile}"
echo "Back to Main Repo"

echo "Hard reset..."
git reset --hard

if [[ "${mainRepoStatus}" =~ "Changes not staged for commit" ]]; then
    echo "Stash apply..." | tee -a "${logFile}"
    git stash pop 2>> "${logFile}" >> "${logFile}"
fi

if [ "${needToUpdateInitSubmodules}" == "true" ]; then
    echo "git submodule update --init..." | tee -a "${logFile}"
    git submodule update --init
fi