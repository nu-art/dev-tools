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

## @function: prompt_WaitForInput(variableName, message, defaultValue?)
##
## @description: Prompt user for input, and assigns it to a variable with the specified name
##
## @return: void
prompt_WaitForInput() {
  local variableName=${1}
  local message=${2}
  local defaultValue=${3}

  if [[ "${defaultValue}" ]]; then
    logInfo "${message} [OR press enter to use the current value]"
    logInfo "    (current=${defaultValue})"
  else
    logInfo "${message}"
  fi

  # shellcheck disable=SC2086
  # shellcheck disable=SC2229
  # shellcheck disable=SC2162
  read ${variableName}
  deleteTerminalLine

  if [[ ! "${!variableName}" ]]; then
    eval "${variableName}='${defaultValue}'"
  fi
}

## @function: prompt_WaitForChoice(resultVar, message, ...options)
##
## @description: Printing a list of choices and prompting the user to choose an option
##
## @return: The selected value
prompt_WaitForChoice() {
  local resultVar=${1}
  local message=${2}
  local options=("${@:3}")

  logVerbose
  logInfo " - ${message}"
  local response=
  select response in "${options[@]}"; do
    deleteTerminalLine
    [[ ! "${response}" ]] && continue

    eval "${resultVar}='${response}'"
    break
  done
  deleteTerminalLine ${#options[@]}

  logDebug "  + Selected: ${response}"
}

## @function: prompt_yesOrNo(resultVar, message, defaultOption)
##
## @description: Printing a list of choices and prompting the user to choose an option
##
## @return: The selected value
prompt_yesOrNo() {
  local resultVar=${1}
  local message=${2}
  local defaultOption=${3}

  logInfo " - ${message}?"
  while [[ ! "${response}" ]]; do

    # shellcheck disable=SC2162
    read -n 1 -p "" response
    logVerbose
    if [[ "${defaultOption}" ]] && [[ "$response" == "" ]]; then
      deleteTerminalLine
      response=${defaultOption}
    fi
    case "$response" in
    [yY])
      deleteTerminalLine
      setVariable "${resultVar}" y
      logDebug "  + Yes"
      ;;

    [nN])
      deleteTerminalLine
      setVariable "${resultVar}" n
      logDebug "  + No"
      ;;

    *)
      deleteTerminalLine
      response=
      ;;
    esac
  done
}
