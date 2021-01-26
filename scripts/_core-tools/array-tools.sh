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

## @function: array_remove(arrayVarName, ...itemToRemoves)
##
## @description: remove the given list of items from the array
##
## @return: void
array_remove() {
  local arrayVarName=${1}
  local itemToRemoves=("${@:2}")

  local temp=
  temp="${arrayVarName}[@]"

  for itemToRemove in "${itemToRemoves[@]}"; do
    for i in $(eval "echo \${!${arrayVarName}[@]}"); do
      temp="${arrayVarName}[${i}]"
      if [[ "${!temp}" == "${itemToRemove}" ]]; then
        unset "${temp}"
      fi
    done
  done
}

## @function: array_filterDuplicates(...list)
##
## @description: filters duplicated items in the list
##
## @return: a filtered list with every item existing only once in it
array_filterDuplicates() {
  local list=("${@}")
  local filteredList=()

  for item in "${list[@]}"; do
    [[ $(array_contains "${item}" "${filteredList[@]}") ]] && continue

    filteredList+=("${item}")
  done

  echo "${filteredList[@]}"
}

## @function: array_isArray(arrayVarName)
##
## @description: will check if the ver name supplied is of type array
##
## @return: true if the varName ref to an array, nothing otherwise
array_isArray() {
  local arrayVarName=${1}
  [[ "$(declare -p arrayVarName)" =~ "declare -a" ]] && echo true
}

array_setVariable() {
  local arrayVarName="${1}"
  local values="${*:2}"
  eval "${arrayVarName}=(${values})"
}
