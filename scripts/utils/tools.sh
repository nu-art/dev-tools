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
source ${BASH_SOURCE%/*}/log-tools.sh

function sedFunc() {
    local data=$1
    local pattern=$2
    local command

    if [[ "$(uname -v)" =~ "Darwin" ]]; then
        command="perl -pe"
    else
        command="sed -E"
    fi

    local result=`echo "${data}" | ${command} "${pattern}"`

    echo "${result}"
}
function setDefaultAndroidHome() {
    if [ "${ANDROID_HOME}" != "" ]; then
        return
    fi

    if [[ "$(uname -v)" =~ "Darwin" ]]; then
        ANDROID_HOME="/Users/${USER}/Library/Android/sdk"
    else
        ANDROID_HOME="~/Android/sdk"
    fi
}

setValue() {
    local name=${1//-/_}
    local value=$2

    logVerbose "setValue p_${name}=\"${value}\""
    declare p_${name}="${value}"  2>> "${logFile}" >> "${logFile}"
}

getValue() {
    local name=p_${1//-/_}
    echo ${!name}
}

pushDir() {
    local folder=$1
    pushd ${folder} 2>> "${logFile}" >> "${logFile}"
}

popDir() {
    popd 2>> "${logFile}" >> "${logFile}"
}

function setProperty() {
	local key=$1
    local value=$2
    local file=$3

	found=`sed -E "s/(${key})=.*/\1/" ${file}`
    if [ "${found}" == "${key}" ]; then
        sed -Ei "s/(${key}=).*/\1${value}/" ${file}
    else
    	echo "${key}=${value}" >> ${file}
    fi
}

function indent() {
    sed "s/^/${1}/";
}

function execute() {
    local message=$1
    local command=$2
    local indentOutput=$3

    echo
    logInfo "${message}"
    logDebug "  ${command}"

    if [ "${indentOutput}" == "false" ]; then
        ${command}
    else
        ${command} | indent "    "
    fi
}