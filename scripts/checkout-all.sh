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

source ${BASH_SOURCE%/*}/utils/git-tools.sh
source ${BASH_SOURCE%/*}/utils/file-tools.sh

branchName=${1}

if [ "${branchName}" == "" ]; then
    logError "Missing branch name"
    exit
fi

for (( lastParam=2; lastParam<=$#; lastParam+=1 )); do
    case "${!lastParam}" in
        "--force")
            force="-b"
        ;;
    esac
done


function processFolder() {
    local folderName=${1}
    folderName=`echo ${folderName} | sed -E 's/\///'`
    execute " Checking out branch ${branchName}" "git checkout ${force} ${branchName}"
}

iterateOverFolders "gitMapSubmodules" processFolder

execute " Checking out branch ${branchName}" "git checkout ${branchName}"

