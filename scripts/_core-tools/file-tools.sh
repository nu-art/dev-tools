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

deleteFile() {
  local pathToFile=${1}
  [[ ! -e "${pathToFile}" ]] && return

  execute "rm ${pathToFile}" "Deleting file: ${pathToFile}"
}

renameFiles() {
  local rootFolder=${1}
  local matchPattern=${2}
  local replaceWith=${3}

  local files=($(find "${rootFolder}" -iname "*${matchPattern}*"))
  for file in "${files[@]}"; do
    local newFile=$(echo "${file}" | sed -E "s/${matchPattern}/${replaceWith}/g")
    mv "${file}" "${newFile}"
  done
}

## @function: file_replaceAll(match, replaceWith, file, delimiter?)
##
## @description: Replaces all substrings matching the provided regexp in the given file
##
## @return: void
file_replaceAll() {
  file_replace "$1" "$2" "$3" g "${4}"
}

## @function: file_deleteLine(match, pathToFile, delimiter?)
##
## @description: Delete all the lines containing or matching the provided match
##
## @return: void
file_deleteLine() {
  local match=${1}
  local pathToFile=${2}
  local delimiter="${5:-/}"

  if [[ $(isMacOS) ]]; then
    sed -i '' -E "/${match}/d" "${pathToFile}"
  else
    sed -i -E "/${match}/d" "${pathToFile}"
  fi

}

## @function: file_replace(match, replaceWith, file, flags?, delimiter?)
##
## @description: Replaces the first substring matching the provided regexp in the given file
##
## @return: void
file_replace() {
  local matchPattern=${1}
  local replaceWith=${2}
  local file="${3}"
  local flags="${4}"
  local delimiter="${5:-/}"

  if [[ $(isMacOS) ]]; then
    sed -i '' -E "s${delimiter}${matchPattern}${delimiter}${replaceWith}${delimiter}${flags}" "${file}"
  else
    sed -i -E "s${delimiter}${matchPattern}${delimiter}${replaceWith}${delimiter}${flags}" "${file}"
  fi
}

file_replaceLine() {
  local toMatch=${1}
  local replacement="${2}"
  local file=${3}

  local fileContent="$(cat "${file}")"
  local matchedLine=$(echo -e "${fileContent}" | grep -n "${toMatch}" | head -n 1 | cut -d: -f1)
  local totalLines=$(echo -n "${fileContent}" | grep -c '^')

  local start="$(echo -e "${fileContent}" | sed -n "1,$((matchedLine - 1))p")"
  local end="$(echo -e "${fileContent}" | sed -n "$((matchedLine + 1)),$((totalLines))p")"
  fileContent="${start}\n${replacement}\n${end}"
  echo -e "${fileContent}" > "${file}"
}
