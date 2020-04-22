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

setDefaultAndroidHome() {
  if [[ "${ANDROID_HOME}" ]]; then
    return
  fi

  if [[ $(isMacOS) ]]; then
    if [[ ! -e "/Users/${USER}/Library/Android/sdk" ]]; then
      # shellcheck disable=SC2230
      local pathToAdb=$(which adb)
      if [[ ${pathToAdb} ]]; then
        ANDROID_HOME=$(echo "${pathToAdb}" | sed -E "s/^(.*)\/platform-tools\/adb$/\1/")
        return
      fi
    fi
    ANDROID_HOME="/Users/${USER}/Library/Android/sdk"
  else
    ANDROID_HOME="$HOME/Android/sdk"
  fi
}

execute() {
  local command=$1
  local message=$2
  local ignoreError=$3

  if [[ "${message}" ]]; then
    logDebug "${message}"
  else
    logDebug "${command}"
  fi

  if [[ "${message}" ]]; then
    logVerbose "  ${command}"
  fi

  local errorCode=
  eval "${command}"
  errorCode=$?

  if [[ "${ignoreError}" == "true" ]]; then
    logVerbose
    throwError "${message}" ${errorCode}
  fi

  return ${errorCode}
}

yesOrNoQuestion() {
  local message=${1}
  local toExecuteYes=${2}
  local toExecuteNo=${3}

  logWarning "${message}"
  # shellcheck disable=SC2162
  read -n 1 -p "" response

  logVerbose
  case "$response" in
  [yY])
    eval "${toExecuteYes}"
    throwError "Error executing: ${toExecuteYes}"
    ;;
  [nN])
    eval "${toExecuteNo}"
    throwError "Error executing: ${toExecuteNo}"
    ;;
  *)
    logError "Canceling..."
    exit 2
    ;;
  esac
}

yesOrNoQuestion_new() {
  local var=${1}
  local message=${2}
  local defaultOption=${3}

  logInfo "${message}"
  # shellcheck disable=SC2162
  read -n 1 -p "" response

  logVerbose
  case "$response" in
  [yY])
    setVariable "${var}" y
    ;;

  [nN])
    setVariable "${var}" n
    ;;

  *)
    if [[ "${defaultOption}" ]] && [[ "$response" == "" ]]; then
      setVariable "${var}" "${defaultOption}"
      return
    fi

    deleteTerminalLine
    deleteTerminalLine
    yesOrNoQuestion_new $@
    ;;
  esac

  deleteTerminalLine
}

choicePrintOptions() {
  local message=${1}
  local options=("${@}")
  options=("${options[@]:1}")

  for ((arg = 0; arg < ${#options[@]}; arg += 1)); do
    local option="${arg}. ${options[${arg}]}"
    logDebug "   ${option}"
  done
  logVerbose
  logWarning "   ${message}"
  logVerbose
}

choiceWaitForInput() {
  local options=("${@}")

  response=-1
  while (("${response}" < 0 || "${response}" >= ${#options[@]})); do
    # shellcheck disable=SC2162
    read -n 1 -p "" response
    response=$(number_assertNumeric "${response}" "-1")
  done

  echo "${options[${response}]}"
}

killProcess() {
  local processName=${1}
  local killMethod=${2} || 15

  if [[ $(isMacOS) ]]; then
    kill "${killMethod}" "${processName}"
  else
    kill "-${killMethod}" "${processName}"
  fi
}

killAllProcess() {
  local processName=${1}
  local killMethod=${2} || 15

  if [[ $(isMacOS) ]]; then
    killall "${killMethod}" "${processName}"
  else
    killall "-${killMethod}" "${processName}"
  fi
}

isMacOS() {
  if [[ "$(uname -v)" =~ "Darwin" ]]; then echo "true"; else echo; fi
}

# To reconsider
replaceStringInFiles() {
  local rootFolder=${1}
  local matchPattern=${2}
  local replaceWith="${3}"
  local excludeDirs=(${@:4})
  local toExclude=""

  for ((arg = 0; arg < ${#excludeDirs[@]}; arg += 1)); do
    toExclude="${toExclude} --exclude-dir=${excludeDirs[${arg}]}"
  done

  # shellcheck disable=SC2086
  local files=($(grep -rl "${matchPattern}" "${rootFolder}"${toExclude}))
  local matchPattern="${matchPattern//\//\\/}"
  local replaceWith="${replaceWith//\//\\/}"

  #    echo sed -i '' -E "s/${matchPattern}/${replaceWith}/g" ${file}
  for file in "${files[@]}"; do
    echo "${file}"
    if [[ $(isMacOS) ]]; then
      sed -i '' -E "s/${matchPattern}/${replaceWith}/g" "${file}"
    else
      sed -i -E "s/${matchPattern}/${replaceWith}/g" "${file}"
    fi
  done
}

replaceAllInFile() {
  replaceInFile "$1" "$2" "$3" g
}

replaceInFile() {
  local matchPattern="${1}"
  local replaceWith="${2}"
  local file="${3}"
  local flags="${4}"

  if [[ $(isMacOS) ]]; then
    sed -i '' -E "s/${matchPattern}/${replaceWith}/${flags}" "${file}"
  else
    sed -i -E "s/${matchPattern}/${replaceWith}/${flags}" "${file}"
  fi
}

isFunction() {
  local functionName=${1}
  [[ $(type -t "${functionName}") == 'function' ]] && echo "function"
}

# shellcheck disable=SC2120
deleteTerminalLine() {
  local count=${1:-1}
  for ((arg = 0; arg < count; arg += 1)); do
    tput cuu1 tput el
  done
  for ((arg = 0; arg < count; arg += 1)); do
    echo "                                                                                                                                              "
  done
  for ((arg = 0; arg < count; arg += 1)); do
    tput cuu1 tput el
  done
}

setVariable() {
  local var=${1}
  local value=${2}
  eval "${var}='${value}'"
}

getMaxLength() {
  local length=${#1}
  for item in "$@"; do
    local itemLength=${#item}
    ((itemLength > length)) && length=${#item}
  done

  echo "${length}"
}

getMinLength() {
  local length=${#1}
  for item in "$@"; do
    local itemLength=${#item}
    ((itemLength < length)) && length=${#item}
  done

  echo "${length}"
}

#K=("adam" "asdas asda s" "sdsds" asdasdasd asdasdas asdasdaas dasd asasdasdasdadasdasasd we)
#getMinLength "${K[@]}"
#generateRandomNumber 8
