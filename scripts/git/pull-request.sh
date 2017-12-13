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

if [ "${1}" == "" ] || [ "${2}" == "" ]; then
    BranchParam="<${paramColor}Branch${NoColor}-(${valueColor}Your branch name${NoColor})>"
    CommitParam="<${paramColor}Commit${NoColor}-(${valueColor}Your commit message${NoColor})>"
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor}   ${BranchParam}   ${CommitParam}"
    echo
    exit 1;
fi

branch=$1
commitMessage=$2
branchExists=`git branch -a |grep " ${branch}"`

if [ "${branchExists}" == "" ]; then
    git branch ${branch}
    checkExecutionError "Unable to create branch ${branch}"
fi

git checkout ${branch}
checkExecutionError "Unable to checkout branch ${branch}"

git push -u origin ${branch}

git add .
stashed=`git stash save`

git pull

git merge origin/master
checkExecutionError "Error while merging master ${branch}"

if [ "${stashed}" != "No local changes to save" ]; then
    git stash apply
    checkExecutionError "Error while applying stash"
fi

git commit -am "${commitMessage}"
checkExecutionError "Error committing changes." 1

git push

checkExecutionError "Error pushing to remote"

project=`git remote -v | head -1 | perl -pe "s/.*:(.*?)(:?.git| ).*/\1/"`
checkExecutionError "Unable to extract remote project name"

url="https://github.com/${project}/compare/${branch}?expand=1"
open ${url}
checkExecutionError "Error launching browser with url: ${url}"
