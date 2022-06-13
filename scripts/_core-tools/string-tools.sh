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

## @function: string_endsWith(string, expected)
##
## @description: Check if a string ends with the expected
##
## @return: true if ends with the expected string, null otherwise
string_endsWith() {
  local string="${1}"
  local expected="${2}"
  [[ "${string: -${#expected}}" == "${expected}" ]] && echo "true"
}

## @function: string_startsWith(string, expected)
##
## @description: Check if a string starts with the expected
##
## @return: true if starts with the expected string, null otherwise
string_startsWith() {
  local string="${1}"
  local expected="${2}"
  [[ "${string:0:${#expected}}" == "${expected}" ]] && echo "true"
}

## @function: string_substring(string, fromIndex, length?)
##
## @description: Substring out of the given string from and to the provided indices
##
## @return: The substring between the given indices
string_substring() {
  local string="${1}"
  local fromIndex=${2}
  local length=${3}
  [[ ! "${length}" ]] && length=$((${#string} - fromIndex))
  echo "${string:${fromIndex}:${length}}"
}

##   == WIP ==
## @function: string_match(string, ...regexps)
##
## @description: Check if a string matches all given regexps
##
## @return: The found matches
string_match() {
  local string="${1}"
  local regexps=("${@:2}")
  local matches=()
  for regexp in ${regexps[@]}; do
    while [[ "${string}" =~ $regexp ]]; do
      matches+=("${BASH_REMATCH[1]}")
      string=$(echo "${string}" | sed -E "s/${BASH_REMATCH[1]}//g")
    done
  done

  echo "${matches[@]}"
}

## @function: string_replace(match, replaceWith, string, delimiter?)
##
## @description: Replaces all occurrences of a substring in a given string matching a regexp
##
## @return: The new edited string
string_replaceAll() {
  string_replace "$1" "$2" "$3" g "${4}"
}

## @function: string_replace(match, replaceWith, string, flags?, delimiter?)
##
## @description: Replaces a substring in a given string matching a regexp
##
## @return: The new edited string
string_replace() {
  local match="${1}"
  local replaceWith="${2}"
  local string="${3}"
  local flags="${4}"
  local delimiter="${5:-/}"

  echo "${string}" | sed -E "s${delimiter}${match}${delimiter}${replaceWith}${delimiter}${flags}"
}

## @function: string_join(delimiter, ...strings)
##
## @description: Joins all string elements with the given delimiter
##
## @return: The new composed string
string_join() {
  local delimiter="${1}"
  local output="${2}"
  for param in ${@:3}; do
    output="${output}${delimiter}${param}"
  done

  echo "${output}"
}

string_generateHex() {
  local length="${1}"
  local hex=""
  for ((charAt = 0; charAt < length; charAt++)); do
    hex="${hex}$(printf "%x" "$(number_random 16)")"
  done

  echo "${hex}"
}

## @function: string_contains(string, substring)
##
## @description: Check if a string contains the given substring
##
## @return: true - Successful
##          "" - Failed
string_match() {
  local string="${1}"
  local substring="${2}"

  [[ "${string}" == *"${substring}"* ]] && echo "true"
}
