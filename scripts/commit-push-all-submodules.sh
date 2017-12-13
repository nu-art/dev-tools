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
    echo "Missing commit message"
    exit
fi

source ${BASH_SOURCE%/*}/utils/file-tools.sh

directories=$(listGitFolders)
directories=(${directories//,/ })
for folderName in "${directories[@]}"; do
    cd ${folderName}
    isClean=`git status | grep "nothing to commit, working directory clean"`
#    echo ${isClean}
    if [ "${isClean}" == "nothing to commit, working directory clean" ]; then
        echo "Skipping clean repo folder ${folderName}"
        cd ..
        continue
    fi

    echo "Found dirty repo folder ${folderName}"
    git commit -am "$1"
    git push
    cd ..
done

