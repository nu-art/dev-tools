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
getRunningDir() {
  echo "${PWD##*/}"
}

copyFileToFolder() {
  local origin="${1}"
  local target="${2}"

  [[ ! -e "${target}" ]] && createDir "${target}"

  cp "${origin}" "${target}"
  execute "cp \"${origin}\" \"${target}\"" "Copying file: ${origin} => ${target}"
}

createDir() {
  createFolder $@
}

createFolder() {
  local pathToDir="${1}"

  [[ -e "${pathToDir}" ]] || [[ -d "${pathToDir}" ]] || [[ -L "${pathToDir}" ]] && return
  [[ -f "${pathToDir}" ]] && throwError "Path already exists as file: $(pwd)/${pathToDir}"

  execute "mkdir -p \"${pathToDir}\"" "Creating folder: ${pathToDir}"
}

clearDir() {
  cleadFolder $@
}

clearFolder() {
  local pathToDir=${1}

  [[ ! -e "${pathToDir}" ]] && return
  [[ -f "${pathToDir}" ]] && throwError "Path is as file: $(pwd)/${pathToDir}"

  _pushd "${pathToDir}"
  execute "rm -rf *" "Deleting folder content: ${pathToDir}"
  _popd
}

deleteFolder() {
  deleteDir $@
}

deleteDir() {
  local pathToDir="${1}"

  [[ -f "${pathToDir}" ]] && throwError "Path is as file: $(pwd)/${pathToDir}"
  [[ ! -e "${pathToDir}" ]] && [[ ! -d "${pathToDir}" ]] && [[ ! -L "${pathToDir}" ]] && return

  execute "rm -rf \"${pathToDir}\"" "Deleting folder: ${pathToDir}"
}

_cd() {
  local pathToDir=${1}
  [[ -z "${pathToDir}" ]] && throwWarning "path is empty" 2
  cd "${pathToDir}" > /dev/null 2>&1 || throwWarning "$(pwd)/${pathToDir} folder does not exists" 2
}

_cd..() {
  cd ..
}

_pushd() {
  local pathToDir=${1}
  [[ -z "${pathToDir}" ]] && throwWarning "path is empty" 2
  pushd "${pathToDir}" > /dev/null 2>&1 || throwWarning "$(pwd)/${pathToDir} folder does not exists" 2
}

_popd() {
  popd > /dev/null 2>&1 || throwWarning "folder does not exists" 2
}

listFoldersImpl() {
  # shellcheck disable=SC2035
  # listing only folders!!
  local folders=($(echo */))

  for folderName in "${folders[@]}"; do
    local add=false

    folderName="${folderName:0:-1}"
    add=true
    for ((arg = 1; arg <= $#; arg += 1)); do
      local result=$(${!arg} "${folderName}")
      if [[ "${result}" == "false" ]]; then
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

listFolders() {
  listFoldersImpl
}

listGitFolders() {
  listFoldersImpl gitFolders
}

listAllGitFolders() {
  listFoldersImpl allGitFolders
}

listAllGradleFolders() {
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
  local directoriesAsString=$(${folderFilter})
  _logDebug "filtered folders: ${directoriesAsString}"
  local directories=("${directoriesAsString}")
  _logDebug "directories(${#directories[@]}): ${directories[*]}"
  for folderName in ${directories[@]}; do
    echo "Processing: ${folderName}"
    #    bannerDebug "Processing: ${folderName}"
    #    _pushd "${folderName}"
    #    ${toExecute} "${folderName}"
    #    _popd
    #    logVerbose "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n"
  done

}
