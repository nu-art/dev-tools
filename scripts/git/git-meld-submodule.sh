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
#
# Inspired by: https://x3ro.de/integrating-a-submodule-into-the-parent-repository/

#!/bin/bash

## NEED TO GET BACK TO THIS ONCE I UNDERSTAND GIT BETTER!!
source ${BASH_SOURCE%/*}/_core.sh

runningDir=$(getRunningDir)
outputFolder="$(pwd)/../.temp"
paramColor=${BRed}

params=(submoduleName runningDir outputFolder)

function extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    "--debug")
      debug="true"
      ;;
    esac
  done
}

#signature "git meld submodule"
extractParams "$@"
printDebugParams ${debug} "${params[@]}"

gitDeinitSubmodule() {
  local branch=master
  logWarning "de-init submodule: ${submodule} on branch: ${branch}"
  local ok=
  local submodule="${1}"
  local submoduleFolder="${outputFolder}/${submodule}"
  _cd "${submodule}"
  local url="$(gitGetRepoUrl)"
  _cd-

  execute "git clone ${url} ${submoduleFolder}"

  _cd "${submoduleFolder}"

  execute "git checkout ${branch}"

  # Last confirmation
  git ls-files -s | sed "s/${CHAR_TAB}/${CHAR_TAB}${submodule}\//"
  prompt_yesOrNo ok "Please take a look at the printed file list. Does it look correct (y/n)..." n
  [[ "${ok}" == "n" ]] && throwError "aborting..." 2

  # The actual processing happens here
  local indexFilter="git ls-files -s | sed \"s/${CHAR_TAB}/${CHAR_TAB}${submodule}\//\" | GIT_INDEX_FILE=\${GIT_INDEX_FILE}.new git update-index --index-info && mv \${GIT_INDEX_FILE}.new \${GIT_INDEX_FILE}"

  git filter-branch --index-filter "$indexFilter" HEAD

  _cd-
  rm -r "${submodule}"
  file_deleteLine "${submodule}" .gitmodules
  git commit -am "melding submodule: ${submodule}"
  git remote add "${submodule}" "${submoduleFolder}"
  git fetch "${submodule}"
  git merge -s ours --no-commit "${submodule}/${branch}" --allow-unrelated-histories
  git clone "${url}"
  rm -rf "${submodule}/.git"
  git commit -am "melded submodule: ${submodule}"
  git remote remove "${submodule}"
}

function pickSubmodules() {
  local varName="${1}"
  local submodulesToRemove=()
  local submodules=()

  while true; do
    git_listSubmodules submodules "project" "dev-tools"
    ((${#submodulesToRemove[@]} > 0)) && submodules=("DONE" "${submodules[@]}")
    array_remove submodules "${submodulesToRemove[@]}"
    local submodule
    clear
    tput sc
    tput rc
    prompt_WaitForChoice submodule "Pick submodule to be melded into the main repo: (${submodulesToRemove[*]})" "${submodules[@]}"
    echo Selected ${submodule}
    [[ "${submodule}" == "DONE" ]] && break
    submodulesToRemove+=("${submodule}")
  done
  logVerbose
  array_setVariable "${varName}" "${submodulesToRemove[@]}"
}

function start() {
  local submodulesToMeld
  local ok=
  pickSubmodules submodulesToMeld

  prompt_yesOrNo ok "Melding submodules (y/n)... '${submodulesToMeld[*]}'" n
  [[ "${ok}" == "n" ]] && throwError "Aborting..." 2

  folder.delete "${outputFolder}"
  folder.create "${outputFolder}"

  for submodule in "${submodulesToMeld[@]}"; do
    gitDeinitSubmodule "${submodule}"
  done

  #  git commit -am "Melded submodules: (${submodulesToMeld[*]})"
}

start
