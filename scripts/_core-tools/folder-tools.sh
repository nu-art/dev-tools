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

folder.getRunningPath() {
  cd "$(dirname "${BASH_SOURCE[${1:-1}]}")" && pwd
}

folder.copyFile() {
  local origin="${1}"
  local target="${2}"

  [[ ! -e "${target}" ]] && folder.create "${target}"

  cp "${origin}" "${target}"
  execute "cp \"${origin}\" \"${target}\"" "Copying file: ${origin} => ${target}" "${2}"
}

folder.create() {
  local pathToDir="${1}"

  [[ -e "${pathToDir}" ]] || [[ -d "${pathToDir}" ]] || [[ -L "${pathToDir}" ]] && return
  [[ -f "${pathToDir}" ]] && throwError "Path already exists as file: $(pwd)/${pathToDir}"

  executeSilent "mkdir -p \"${pathToDir}\"" "Creating folder: ${pathToDir}" "${2}"
}

folder.clear() {
  local pathToDir=${1}

  [[ ! -e "${pathToDir}" ]] && return
  [[ -f "${pathToDir}" ]] && throwError "Path is as file: $(pwd)/${pathToDir}"

  _pushd "${pathToDir}"
  executeSilent "rm -rf *" "Deleting folder content: ${pathToDir}" "${2}"
  _popd
}

folder.delete() {
  local pathToDir="${1}"

  [[ -f "${pathToDir}" ]] && throwError "Path is as file: $(pwd)/${pathToDir}"
  [[ ! -e "${pathToDir}" ]] && [[ ! -d "${pathToDir}" ]] && [[ ! -L "${pathToDir}" ]] && return

  executeSilent "rm -rf \"${pathToDir}\"" "Deleting folder: ${pathToDir}" "${2}"
}

_cd() {
  local pathToDir=${1}
  [[ -z "${pathToDir}" ]] && throwWarning "path is empty" 2
  cd "${pathToDir}" > /dev/null 2>&1 || throwWarning "$(pwd)/${pathToDir} folder does not exists" 2
}

_cd..() {
  cd ..
}

_cd-() {
  cd -
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
      if [[ ! "${result}" ]]; then
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

listGradleModulesFolders() {
  listFoldersImpl allGradleFolders moduleFolder
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
    _pushd "${folderName}"
    ${toExecute} "${folderName}"
    _popd
  done

}
