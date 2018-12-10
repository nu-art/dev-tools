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

source ${BASH_SOURCE%/*}/../utils/file-tools.sh
source ${BASH_SOURCE%/*}/tools.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh

projectsToIgnore=("dev-tools")

stashName=${1}
if [ "${stashName}" == "" ]; then
    stashName="pull-all-script"
fi

pids=()
function process() {
    logInfo "${GIT_TAG} Stashing changes with message: ${stashName}"
    local result=`git stash save "${stashName}"`

    gitPullRepo

    if [ "${result}" != "No local changes to save" ]; then
        gitStashPop
    fi
}

function processFolder() {
    local folder=${1}
    cd ${folder}
        local submoduleBranch=`gitGetCurrentBranch`
        if [ "${mainRepoBranch}" != "${submoduleBranch}" ]; then
            cd ..
            git submodule udpate ${folder}
            return
        fi
        process &
        pid=$!
        pids+=(${pid})
    cd ..
}

signature
bannerDebug "Processing: Main Repo"
mainRepoBranch=`gitGetCurrentBranch`
process

changedSubmodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
echo
echo "changedSubmodules: ${changedSubmodules[@]}"

if [ "${changedSubmodules#}" == "0" ]; then
    exit 0
fi

for submoduleName in "${changedSubmodules[@]}"; do
    processFolder ${submoduleName}
done

echo "pids: ${pids[@]}"
for pid in "${pids[@]}"; do
    wait ${pid}
done
