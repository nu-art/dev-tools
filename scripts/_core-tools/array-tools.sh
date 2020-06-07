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

## @function: array_contains(item, ...list)
##
## @description: Check if an item is in a list
##
## @return: true if contained, null otherwise
array_contains() {
  for i in "${@:2}"; do
    if [[ "${i}" == "${1}" ]]; then
      echo "true"
      return
    fi
  done
}

## @function: array_remove(arrayVarName, itemToRemove)
##
## @description: remove the give item from the array if it exists
##
## @return: void
array_remove() {
  local arrayVarName=${1}
  local itemToRemove=${2}

  local temp=
  temp="${arrayVarName}[@]"

  for i in $(eval "echo \${!${arrayVarName}[@]}"); do
    temp="${arrayVarName}[${i}]"
    if [[ "${!temp}" == "${itemToRemove}" ]]; then
      unset "${temp}"
    fi
  done
}

## @function: array_filterDuplicates(...list)
##
## @description: filters duplicated items in the list
##
## @return: a filtered list with every item existing only once in it
array_filterDuplicates() {
  local list=(${@})
  local filteredList=()

  for item in ${list[@]}; do
    [[ $(array_contains "${item}" ${filteredList[@]}) ]] && continue
    #      echo "adding item: ${item}"

    filteredList+=(${item})
  done

  echo "${filteredList[@]}"
}

array_isArray() {
  [[ "$(declare -p variable_name)" =~ "declare -a" ]] && echo true
}
