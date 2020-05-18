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
LOG_LEVEL__VERBOSE=0
LOG_LEVEL__DEBUG=1
LOG_LEVEL__INFO=2
LOG_LEVEL__WARNING=3
LOG_LEVEL__ERROR=4

logLevel=${LOG_LEVEL__VERBOSE}
LOG_COLORS=("${NoColor}" "${BBlue}" "${BGreen}" "${BYellow}" "${BRed}")
LOG_PREFIX=("-V-" "-D-" "-I-" "-W-" "-E-")

CONST_Debug=
CONST_DebugFile=

setDebugLogFile() {
  CONST_DebugFile=${1}
  CONST_Debug=true
  deleteFile "${CONST_DebugFile}"
}
setDebugLog() {
  CONST_Debug=${1}
}

setLogLevel() {
  case ${1} in
  0 | 1 | 2 | 3 | 4)
    logLevel=${1}
    ;;

  *)
    logError "Wrong log level"
    exit
    ;;
  esac
}

setSummaryFile() {
  summaryFile="${1}"
  echo "#!/bin/bash" > "${summaryFile}"
  echo "echo " >> "${summaryFile}"
  echo "echo " >> "${summaryFile}"
  echo "echo -e \"${BCyan} ----------------   ___ _   _ __  __ __  __   _   _____   __  ---------------- ${NoColor}\"" >> "${summaryFile}"
  echo "echo -e \"${BCyan} ----------------  / __| | | |  \/  |  \/  | /_\ | _ \ \ / /  ---------------- ${NoColor}\"" >> "${summaryFile}"
  echo "echo -e \"${BCyan} ----------------  \__ \ |_| | |\/| | |\/| |/ _ \|   /\ V /   ---------------- ${NoColor}\"" >> "${summaryFile}"
  echo "echo -e \"${BCyan} ----------------  |___/\___/|_|  |_|_|  |_/_/ \_\_|_\ |_|    ---------------- ${NoColor}\"" >> "${summaryFile}"
  echo "echo -e \"${BCyan} ----------------                                             ---------------- ${NoColor}\"" >> "${summaryFile}"
  echo "echo " >> "${summaryFile}"

}

setLogFile() {
  setLogLevel "${1}"
  local relativePathToLogFolder=${2}
  local logFilePrefix=${3}

  local logsFolder="$(pwd)/${relativePathToLogFolder}"
  local dateTimeFormatted=$(date +%Y-%m-%d--%H-%M-%S)

  [[ ! -d "${logsFolder}" ]] && mkdir -p "${logsFolder}"

  logFile="${logsFolder}/${logFilePrefix}-log-${dateTimeFormatted}.txt"
  echo > "${logFile}"
}

log() {
  local level=$1
  local logMessage=$2
  local override=$3
  local _override

  local color=${LOG_COLORS[${level}]}

  [[ "${override}" ]] && _override="n"

  ((level < logLevel)) && return

  #    For Debug
  #    echo "echo -e${_override} \"${color}${logMessage}${NoColor}\"\\r"
  startTimer "log-tools"
  local duration=$(calcDuration "rootTimer")
  logDate="(${duration}) "$(date +"%Y-%m-%d_%H:%M:%S")
  logMessage=${logMessage//$'\n'/'\n'${NoColor}${logDate} ${color}}
  echo -e${_override} "${logDate}  ${color}${logMessage}${NoColor}"\\r
}

logVerbose() {
  log 0 "${1}" "${2}"
}

logDebug() {
  log 1 "${1}" "${2}"
}

logInfo() {
  log 2 "${1}" "${2}"
}

logWarning() {
  log 3 "${1}" "${2}"
}

logError() {
  log 4 "${1}" "${2}"
}

bannerVerbose() {
  banner 0 "${1}" "${2}"
}

bannerDebug() {
  banner 1 "${1}" "${2}"
}

bannerInfo() {
  banner 2 "${1}" "${2}"
}

bannerWarning() {
  banner 3 "${1}" "${2}"
}

bannerError() {
  banner 4 "${1}" "${2}"
}

banner() {
  local level=$1
  local logMessage=$2
  local color=$3
  local nocolor=${LOG_COLORS[${level}]}

  local add="$(echo "$logMessage" | sed -E 's/./-/g')"
  log ${level} "+---$add---+"
  log ${level} "|   ${color}${logMessage}${nocolor}   |"
  log ${level} "+---$add---+"
}

_logVerbose() {
  _log logVerbose "${@}"
}

_logDebug() {
  _log logDebug "${@}"
}

_logInfo() {
  _log logInfo "${@}"
}

_logWarning() {
  _log logWarning "${@}"
}

_logError() {
  _log logError "${@}"
}

_log() {
  [[ ! "${CONST_Debug}" ]] && return
  [[ "${CONST_DebugFile}" ]] && ${1} >&2 "- DEBUG - ${@:2}" >> "${CONST_DebugFile}" && return
  ${1} >&2 "- DEBUG - ${@:2}"
}
