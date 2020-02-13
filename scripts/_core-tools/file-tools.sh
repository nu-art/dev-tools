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

function getRunningDir(){
    echo ${PWD##*/}
}

function copyFileToFolder() {
    local origin="${1}"
    local target="${2}"

    [[ ! -e "${target}" ]] && createDir ${target}

    cp ${origin} ${target}
    execute "cp ${origin} ${target}" "Copying file: ${origin} => ${target}"
}

function createDir() {
    local pathToDir="${1}"
    [[ -e "${pathToDir}" ]] && return

    execute "mkdir -p ${pathToDir}" "Creating folder: ${pathToDir}"
}

function deleteFile() {
    local pathToFile="${1}"
    [[ ! -e "${pathToFile}" ]] && return

    execute "rm ${pathToFile}" "Deleting file: ${pathToFile}"
}

function deleteFolder() {
    deleteDir $@
}

function deleteDir() {
    local pathToDir="${1}"
    [[ ! -e "${pathToDir}" ]] && [[ ! -d "${pathToDir}" ]] && [[ ! -L "${pathToDir}" ]] && return

    execute "rm -rf ${pathToDir}" "Deleting folder: ${pathToDir}"
}

function clearFolder() {
    local pathToDir="${1}"
    [[ ! -e "${pathToDir}" ]] && return

    cd ${pathToDir}
        execute "rm -rf *" "Deleting folder content: ${pathToDir}"
    cd ..
}

function renameFiles() {
    local rootFolder=${1}
    local matchPattern=${2}
    local replaceWith=${3}

    local files=(`find "${rootFolder}" -iname "*${matchPattern}*"`)
    for file in ${files[@]} ; do
        local newFile=`echo ${file} | sed -E "s/${matchPattern}/${replaceWith}/g"`
        mv ${file} ${newFile}
    done
}