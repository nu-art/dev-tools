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

source ${BASH_SOURCE%/*}/_core.sh

runningDir=$(getRunningDir)
paramColor=${BRed}

params=(submoduleName)

function extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    "--submodule="*)
      submoduleName=$(echo "${paramValue}" | sed -E "s/--submodule=(.*)/\1/")
      ;;

    "--debug")
      debug="true"
      ;;
    esac
  done
}

function printUsage() {
  logVerbose
  logVerbose "   USAGE:"
  logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --submodule=${submoduleName}"
  logVerbose
  exit 0
}

extractParams "$@"

#signature "git meld submodule"
#printCommand "$@"
#printDebugParams ${debug} "${params[@]}"
function abort() {
  logError $1
  exit 1
}

gitDeinitSubmodule() {
  logWarning "de-init submodule: ${submodule}"
  local submodule="${1}"
  _cd "${submodule}"
  local url="$(gitGetRepoUrl)"
  local branch=master
  _cd..
  createDir ".temp"
  _cd ".temp"
  git clone "${url}" "${submodule}"
  _cd "${submodule}"
  git checkout "${branch}"

  TARGET_PATH=$(echo -n "$REPLY" | sed -e 's/[\/&]/\\&/g')

  # Last confirmation
  git ls-files -s | sed "s/${CHAR_TAB}/${CHAR_TAB}${submodule}\//"
  request_confirmation "Please take a look at the printed file list. Does it look correct?"

  # The actual processing happens here
  CMD="git ls-files -s | sed \"s/${CHAR_TAB}/${CHAR_TAB}${submodule}\//\" | GIT_INDEX_FILE=\${GIT_INDEX_FILE}.new git update-index --index-info && mv \${GIT_INDEX_FILE}.new \${GIT_INDEX_FILE}"

  git filter-branch \
    --index-filter "$CMD" \
    HEAD

  _cd..
  _cd..
#  git submodule deinit "${submodule}"
#  git rm -rf --cache "${submodule}"
  git remote add "_${submodule}" ".temp/${submodule}"
  git merge -s ours --no-commit "_${submodule}/${branch}" --allow-unrelated-histories
}

function pickSubmodules() {
  local varName="${1}"
  local submodulesToRemove=()
  while true; do
    local submodules=($(getSubmodulesByScope "project" "dev-tools"))
    ((${#submodulesToRemove[@]} > 0)) && submodules=("DONE" "${submodules[@]}")
    array_remove submodules "${submodulesToRemove[@]}"
    local submodule
    clear
    tput sc
    tput rc
    prompt_WaitForChoice submodule "Pick submodule to be melded into the main repo: (${submodulesToRemove[*]})" "${submodules[@]}"
    [[ "${submodule}" == "DONE" ]] && break
    submodulesToRemove+=("${submodule}")
  done
  logVerbose
  array_setVariable "${varName}" "${submodulesToRemove[@]}"
}

function execute() {
  local submodulesToMeld
  local ok
  pickSubmodules submodulesToMeld
  prompt_yesOrNo ok "Melding submodules '${submodulesToMeld[*]}'" n
  [[ "${ok}" == "n" ]] && return

  for submodule in "${submodulesToMeld[@]}"; do
    gitDeinitSubmodule "${submodule}"
  done

  #  git commit -am "Melded submodules: (${submodulesToMeld[*]})"
}
function request_confirmation() {
  read -p "$(tput setaf 4)$1 (y/n) $(tput sgr0)"
  [ "$REPLY" == "y" ] || abort "Aborted!"
}

execute

function processSubmodule() {

  function request_input() {
    read -p "$(tput setaf 4)$1 $(tput sgr0)"
  }

  function request_confirmation() {
    read -p "$(tput setaf 4)$1 (y/n) $(tput sgr0)"
    [ "$REPLY" == "y" ] || abort "Aborted!"
  }

  cat << "EOF"
This script rewrites your entire history, moving the current repository root
into a subdirectory. This can be useful if you want to merge a submodule into
its parent repository.

For example, your main repository might contain a submodule at the path src/lib/,
containing a file called "test.c".
If you would merge the submodule into the parent repository without further
modification, all the commits to "test.c" will have the path "/test.c", whereas
the file now actually lives in "src/lib/test.c".

If you rewrite your history using this script, adding "src/lib/" to the path
and the merging into the parent repository, all paths will be correct.

NOTE: This script might complete garble your repository, so PLEASE apply this
only to a clone of the repository where it does not matter if the repo is destroyed.

EOF

  request_confirmation "Do you want to proceed?"

  cat << "EOF"
Please provide the path which should be prepended to the current root. In the
above example, that would be "src/lib". Please note that the path MUST NOT contain
a trailing slash.

EOF

  request_input "Please provide the desired path (e.g. 'src/lib'):"
  # Escape input for SED, taken from http://stackoverflow.com/a/2705678/124257
  TARGET_PATH=$(echo -n "$REPLY" | sed -e 's/[\/&]/\\&/g')

  # Last confirmation
  git ls-files -s | sed "s/${TAB}/${TAB}$TARGET_PATH\//"
  request_confirmation "Please take a look at the printed file list. Does it look correct?"

  # The actual processing happens here
  CMD="git ls-files -s | sed \"s/${TAB}/${TAB}$TARGET_PATH\//\" | GIT_INDEX_FILE=\${GIT_INDEX_FILE}.new git update-index --index-info && mv \${GIT_INDEX_FILE}.new \${GIT_INDEX_FILE}"

  git filter-branch \
    --index-filter "$CMD" \
    HEAD

}
