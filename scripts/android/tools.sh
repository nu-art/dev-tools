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

waitForDevice() {
    local deviceId=${1}
    local wait=
    if [[ ! ${2} ]]; then
        wait=30
    else
        wait=$((${2}-1))
    fi
    local message=${3}

    if [[ ! "${deviceId}" ]]; then
        throwError "Error waiting for device... no deviceId specified!!" 2
    fi

    local device=`adb devices | grep ${deviceId}`

    if [[ "${wait}" == "0" ]]; then
        logVerbose
        logError "Device connection timed out"
        exit 3
    fi

    if [[ "${device}" ]]; then
        logVerbose
        return
    fi

    if  [[ ! "${message}" ]]; then
        message="Waiting for device '${deviceId}'"
    fi

    logWarning "${message}... ${wait}s  " true
    sleep 1
    waitForDevice ${deviceId} ${wait} ${3}
}