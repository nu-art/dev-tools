#!/bin/bash

## @function: string.endsWith(string, expected)
##
## @description: Check if a string ends with the expected
##
## @return: true if ends with the expected string, null otherwise
string.endsWith() {
  local string="$1"
  local expected="$2"
  [[ "${string: -${#expected}}" == "$expected" ]] && echo "true"
}

## @function: string.startsWith(string, expected)
##
## @description: Check if a string starts with the expected
##
## @return: true if starts with the expected string, null otherwise
string.startsWith() {
  local string="$1"
  local expected="$2"
  [[ "${string:0:${#expected}}" == "$expected" ]] && echo "true"
}

## @function: string.substring(string, fromIndex, length?)
##
## @description: Extracts a substring from the given string
##
## @return: The substring between the given indices
string.substring() {
  local string="$1"
  local fromIndex=$2
  local length=$3
  [[ -z "$length" ]] && length=$((${#string} - fromIndex))
  echo "${string:${fromIndex}:${length}}"
}

## @function: string.contains(string, substring)
##
## @description: Check if a string contains the given substring
##
## @return: true - Successful, "" - Failed
string.contains() {
  local string="$1"
  local substring="$2"
  [[ "$string" == *"$substring"* ]] && echo "true"
}

## @function: string.replace(match, replaceWith, string, flags?, delimiter?)
##
## @description: Replaces a substring in a given string matching a regexp
##
## @return: The new edited string
string.replace() {
  local match="$1"
  local replaceWith="$2"
  local string="$3"
  local flags="$4"
  local delimiter="${5:-/}"

  echo "$string" | sed -E "s${delimiter}${match}${delimiter}${replaceWith}${delimiter}${flags}"
}

## @function: string.replaceAll(match, replaceWith, string, delimiter?)
##
## @description: Replaces all occurrences of a substring in a given string
##
## @return: The new edited string
string.replaceAll() {
  string.replace "$1" "$2" "$3" g "$4"
}

## @function: string.join(delimiter, ...strings)
##
## @description: Joins all string elements with the given delimiter
##
## @return: The new composed string
string.join() {
  local delimiter="$1"
  shift
  local result="$1"
  shift
  for part in "$@"; do
    result+="$delimiter$part"
  done
  echo "$result"
}

