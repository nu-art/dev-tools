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

message=${1}
if [ "${message}" == "" ]; then
    message="pull-all-script"
fi

function process() {
    isClean=`git status | grep "nothing to commit.*"`
    if [ "${isClean}" == "" ]; then
        gitSaveStash ${message}
    fi

    gitPullRepo

    if [ "${isClean}" == "" ]; then
        gitStashPop
    fi
}

function processFolder() {
    local folder=${1}
    cd ${folder}
        process
    cd ..
}

bannerDebug "Processing: Main Repo"
gitPullRepo

executeProcessor processFolder listGitFolders