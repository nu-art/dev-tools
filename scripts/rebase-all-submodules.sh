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
if [ "$1" == "" ]; then
    echo "Missing origin branch"
    exit
fi

if [ "$2" == "" ]; then
    echo "Missing target branch"
    exit
fi

originBranch=$1
targetBranch=$2

source ${BASH_SOURCE%/*}/utils/file-tools.sh

directories=$(listGitFolders)
directories=(${directories//,/ })
for folderName in "${directories[@]}"; do
    cd ${folderName}
    git pull

    hasTargetBranch=`git branch -a | grep "${targetBranch}"`
    hasOriginBranch=`git branch -a | grep "${originBranch}"`

    if [ "${hasOriginBranch}" == "" ]; then
        echo "No Origin branch found: ${originBranch} in repo: ${folderName}"
        cd ..
        continue
    fi
    if [ "${hasTargetBranch}" == "" ]; then
        echo "No Origin branch found: ${targetBranch} in repo: ${folderName}"
        cd ..
        continue
    fi

    echo "---- Found valid repo folder ${folderName}"
    git checkout ${targetBranch}
    git merge ${originBranch}
    git push
    git checkout ${originBranch}
    cd ..
done

