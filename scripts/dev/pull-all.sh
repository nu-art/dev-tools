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

pids=()
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
        process &
        pid=$!
        pids+=(${pid})
    cd ..
}

bannerDebug "Processing: Main Repo"
gitPullRepo

executeProcessor processFolder listGitFolders
echo "pids: ${pids[@]}"

for pid in "${pids[@]}"; do
    wait ${pid}
done

#cmd1 &
#cmd1_pid=$!
#sleep 10
#cmd2
#sleep 10
#cmd2
#wait $cmd1_pid

#explanation: cmd1 & launches a process in the background of the shell. the $! variable contains
#the pid of that background process. the shell keeps processing the other cmds. sleep 10 means
#'wait a little while'. OP just wants to fire cmd2 in linear order so that part is trivial.
# at the end of the script snippet we just wait for cmd1 to finish (it might be even finished earlier)
# with wait $cmd1_pid.


