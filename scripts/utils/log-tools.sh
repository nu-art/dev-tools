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

source ${BASH_SOURCE%/*}/coloring.sh
logLevel=${LOG_LEVEL__VERBOSE}

setLogLevel() {
    case ${1} in
        0|1|2|3|4)
            logLevel=${1}
        ;;

        *)
            logError "Wrong log level"
            exit;
        ;;
    esac
}

setLogFile() {
    dateTimeFormatted=`date +%Y-%m-%d--%H-%M-%S`
    local logsFolder="$(pwd)/${1}"
    if [ ! -d "${logsFolder}" ]; then
        mkdir -p "${logsFolder}"
    fi

    logFile="${logsFolder}/${2}-log-${dateTimeFormatted}.txt"
    echo > "${logFile}"
}

createResultBashFile(){
    echo "#!/bin/bash" > "${1}"
    echo "echo " >>"${1}"
    echo "echo " >>"${1}"
    echo "echo -e \"${BCyan} ----------------   ___ _   _ __  __ __  __   _   _____   __  ---------------- ${NoColor}\"" >>"${1}"
    echo "echo -e \"${BCyan} ----------------  / __| | | |  \/  |  \/  | /_\ | _ \ \ / /  ---------------- ${NoColor}\"" >>"${1}"
    echo "echo -e \"${BCyan} ----------------  \__ \ |_| | |\/| | |\/| |/ _ \|   /\ V /   ---------------- ${NoColor}\"" >>"${1}"
    echo "echo -e \"${BCyan} ----------------  |___/\___/|_|  |_|_|  |_/_/ \_\_|_\ |_|    ---------------- ${NoColor}\"" >>"${1}"
    echo "echo -e \"${BCyan} ----------------                                             ---------------- ${NoColor}\"" >>"${1}"
    echo "echo " >>"${1}"
}

log() {
    local level=$1
    local color=$2
    local levelPrefix=$3
    local logMessage=$4
    local extraFile=$5
    local printToConsole=$6

    if (( ${level} < ${logLevel}  )); then
        return;
    fi

    if [ "${printToConsole}" != "false" ]; then
        echo -e "${color}${logMessage}${NoColor}"
    fi

    if [ "${logFile}" != "" ]; then
        echo "${levelPrefix} ${logMessage}" >> "${logFile}"
    fi

    if [ "${extraFile}" != "" ]; then
        echo "echo -e \"${color}${logMessage}${NoColor}\"" >> "${extraFile}"
    fi
}

logVerbose() {
    log 0 "${NoColor}" "-V-" "${1}" "${2}" "${3}"
}

logDebug() {
    log 1 "${BBlue}" "-D-" "${1}" "${2}" "${3}"
}

logInfo() {
    log 2 "${BGreen}" "-I-" "${1}" "${2}" "${3}"
}

logWarning() {
    log 3 "${BYellow}" "-W-" "${1}" "${2}" "${3}"
}

logError() {
    log 4 "${BRed}" "-E-" "${1}" "${2}" "${3}"
}