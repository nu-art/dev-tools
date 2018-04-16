#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#          Copyright (C) 2017  Adam van der Kruk aka TacB0sS
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

source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh

paramColor=${BBlue}
valueColor=${BGreen}

if [ "${1}" == "" ] || [ "${2}" == "" ] || [ "${3}" == "" ]; then
    FromBranchParam="<${paramColor}From Branch${NoColor}-(${valueColor}Branch to merge from${NoColor})>"
    ToBranchParam="<${paramColor}To Branch${NoColor}-(${valueColor}Branch to merge into${NoColor})>"
    CommitParam="<${paramColor}Commit${NoColor}-(${valueColor}Your commit message${NoColor})>"
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor}   ${FromBranchParam}  ${ToBranchParam}   ${CommitParam}"
    echo
    exit 1;
fi

fromBranch=$1
toBranch=$2
commitMessage=$3
branchExists=`git branch -a |grep " ${fromBranch}"`

if [ "${branchExists}" == "" ]; then
    git branch ${fromBranch}
    checkExecutionError "Unable to create branch ${fromBranch}"
fi

stashed=`git stash save`
git checkout ${fromBranch}
checkExecutionError "Unable to checkout branch ${fromBranch}"

git push -u origin ${fromBranch}

git add .

git pull

git merge origin/${toBranch}
checkExecutionError "Error while merging ${toBranch} ${fromBranch}"

if [ "${stashed}" != "No local changes to save" ]; then
    git stash apply
    checkExecutionError "Error while applying stash"
fi

git submodule update --init
checkExecutionError "Error updating submodules."

git commit -am "${commitMessage}"
checkExecutionError "Error committing changes." 1

git push

checkExecutionError "Error pushing to remote"

project=`git remote -v | head -1 | perl -pe "s/.*:(.*?)(:?.git| ).*/\1/"`
checkExecutionError "Unable to extract remote project name"

url="https://github.com/${project}/compare/${toBranch}...${fromBranch}?expand=1"
echo "URL: ${url}"
open ${url}
checkExecutionError "Error launching browser with url: ${url}"
