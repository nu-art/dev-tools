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

NEWLINE=$'\n'
TAB=$'\t'

directories=$(listAllGitFolders)
directories=(${directories//,/ })
for folderName in "${directories[@]}"; do
    pushd ${folderName} >> /dev/null
#
        if [[ "$(uname -v)" =~ "Darwin" ]]; then
            url=`git remote -v | grep push | perl -pe 's/origin\s//' | perl -pe 's/\s\(push\)//'`
        else
            url=`git remote -v | grep push | sed -E 's/origin\s//' | sed -E 's/\s\(push\)//'`
        fi
        branch=`git status | grep -e 'On branch' | sed -E 's/On branch//'`

        if [ "${branch}" == "" ]; then
            branch=master
        fi

        finalOutput="${finalOutput}[submodule \"${folderName}\"]${NEWLINE}"
        finalOutput="${finalOutput}${TAB}path = ${folderName} ${NEWLINE}"
        finalOutput="${finalOutput}${TAB}url = ${url} ${NEWLINE}"
        finalOutput="${finalOutput}${TAB}branch = ${branch} ${NEWLINE}"
    popd  >> /dev/null

    git submodule add ${url} ${folderName}
done

echo -e $"${finalOutput}" > ./.gitmodules
