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
#    execute "command" "logmessage"

function getRunningDir(){
    echo ${PWD##*/}
}

function createDir() {
    local pathToDir="${1}"
    if [[ -e "${pathToDir}" ]]; then return; fi

    execute "mkdir -p ${pathToDir}" "Creating folder: ${pathToDir}"
}

function deleteFile() {
    local pathToFile="${1}"
    if [[ ! -e "${pathToFile}" ]]; then return; fi

    execute "rm ${pathToFile}" "Deleting file: ${pathToFile}"
}

function deleteDir() {
    local pathToDir="${1}"
    if [[ ! -e "${pathToDir}" ]] && [[ ! -d "${pathToDir}" ]] && [[ ! -L "${pathToDir}" ]]; then return; fi

    execute "rm -rf ${pathToDir}" "Deleting folder: ${pathToDir}"
}

function clearFolder() {
    local pathToDir="${1}"
    if [[ ! -e "${pathToDir}" ]]; then return; fi

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

function renameStringInFiles() {
    local rootFolder=${1}
    local matchPattern=${2}
    local replaceWith="${3}"
    local files=(`grep -rl ${matchPattern} "${rootFolder}"`)

    for file in ${files[@]} ; do
        if [[ `isMacOS` ]]; then
            sed -i '' -E "s/${matchPattern}/${replaceWith}/g" ${file}
        else
            sed -i -E "s/${matchPattern}/${replaceWith}/g" ${file}
        fi
    done
}