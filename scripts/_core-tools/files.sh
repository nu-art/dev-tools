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

allFolders() {
    echo true;
}

allGitFolders() {
    if [[ -e "${1}/.git" ]]; then
        echo true
        return
    fi

    echo false
}

gitFolders() {
    if [[ "${1}" == "dev-tools" ]]; then
        echo false
        return
    fi

    if [[ -e "${1}/.git" ]]; then
        echo true
        return
    fi

    echo false
}

moduleFolder() {
    if [[ "`cat ${1}/build.gradle | grep com.android.application`" =~ "com.android.application" ]]; then
        echo false
        return
    fi

    echo true
}

androidAppsFolder() {
    if [[ "`cat ${1}/build.gradle | grep com.android.application`" =~ "com.android.application" ]]; then
        echo true
        return
    fi

    echo false
}

allGradleFolders(){
    if [[ -e "${1}/build.gradle" ]]; then
        echo true
        return
    fi

    echo false
}

listFoldersImpl() {
    local folders=(`echo */`)

    for folderName in "${folders[@]}"; do
        local add= false

        folderName="${folderName:0: -1}"
        add=true
        for (( arg=1; arg<=$#; arg+=1 )); do
            if [[ "`${!arg} \"${folderName}\"`" == "false" ]]; then
                add=
                break
            fi
        done

        if [[ "${add}" ]]; then
            directories+=(${folderName})
        fi

    done
    echo "${directories[@]}"
}


listFolders(){
    listFoldersImpl allFolders
}

listGitFolders(){
    listFoldersImpl gitFolders
}

listAllGitFolders(){
    listFoldersImpl allGitFolders
}

listAllGradleFolders(){
    listFoldersImpl allGradleFolders
}

listGradleGitFolders() {
    listFoldersImpl allGradleFolders allGitFolders
}

listGradleGitModulesFolders() {
    listFoldersImpl allGradleFolders allGitFolders moduleFolder
}

listGradleAndroidAppsFolders() {
    listFoldersImpl allGradleFolders allGitFolders androidAppsFolder
}

iterateOverFolders() {
    local folderFilter=${1}
    local toExecute=${2}

    local directories=$(${folderFilter})
    directories=(${directories//,/ })

    for folderName in "${directories[@]}"; do
        bannerDebug "Processing: ${folderName}"
        pushd ${folderName} > /dev/null
            ${toExecute} ${folderName}
        popd > /dev/null
        logVerbose "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n"
    done

}