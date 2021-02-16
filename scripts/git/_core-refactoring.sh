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

# !/bin/bash

## @function: git_listSubmodules(varName, scope, ...toIgnore)
##
## @param: scope = project | all | changed | conflict
## @description: Check if an item is in a list
##
## @return: true if contained, null otherwise
git_listSubmodules() {
  local _submodules=()

  git_listAllSubmodules() {
    # shellcheck disable=SC2035
    # listing only folders!!
    local folders=($(echo */))
    local folderName=
    for folderName in "${folders[@]}"; do
      folderName="${folderName:0:-1}"
      [[ ! -e "${folderName}/.git" ]] && continue
      _submodules+=("${folderName}")
    done
  }

  git_listProjectSubmodules() {
    [[ ! -e ".gitmodules" ]] && return

    local submodule
    while IFS='' read -r line || [[ -n "$line" ]]; do
      [[ ! "${line}" =~ "submodule" ]] && continue
      submodule=$(echo "${line}" | sed -E 's/\[submodule "(.*)"\]/\1/')

      [[ ! "${submodule}" ]] && throwError "Error extracting submodule name from line: ${line}" 2
      [[ ! -e "${submodule}/.git" ]] && continue

      _submodules+=("${submodule}")
    done < .gitmodules
  }

  git_listChangedSubmodules() {
    _submodules+=($(git status | grep -e "modified: .*(" | sed -E "s/.*modified: (.*)\(.*/\1/"))
  }

  git_listAllConflictingSubmodules() {
    local conflicts=($(git status | grep -E "both modified: .*" | sed -E "s/.*both modified: (.*)/\1/"))
    for conflict in "${conflicts[@]}"; do
      [[ ! -e "${conflict}/.git" ]] && continue
      _submodules+=("${conflict}")
    done
  }

  local varName="${1}"
  local scope="${2}"
  local toIgnore=("${@:3}")

  case "${scope}" in
  "changed")
    git_listChangedSubmodules
    git_listAllConflictingSubmodules
    ;;

  "all")
    listGitFolders
    ;;

  "project")
    git_listProjectSubmodules
    ;;

  "conflict")
    git_listAllConflictingSubmodules
    ;;

  *)
    throwError "Unsupported submodule scope: ${scope}" 2
    ;;
  esac

  array_remove _submodules "${toIgnore[@]}"
  array_setVariable "${varName}" "${_submodules[@]}"
}

git_getCurrentCommitId() {
  git show HEAD --pretty=format:"%H" --no-patch
}
