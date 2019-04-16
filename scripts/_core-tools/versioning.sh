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

function checkMinVersion() {
    local _version=${1}
    local _minVersion=${2}

    if [[ ! "${_minVersion}" ]]; then return; fi

    local minVersion=(${_minVersion//./ })
    local version=(${_version//./ })

    for (( arg=0; arg<${#minVersion[@]}; arg+=1 )); do
        local min="${minVersion[${arg}]}"
        local current="${version[${arg}]}"

        if (( ${current} > ${min})); then
            echo
            return
        elif (( ${current} == ${min})); then
            continue
        else
            echo true
        fi
    done
}

function promoteVersion() {
    local _version=${1}
    local promotion=${2}
    local version=(${_version//./ })
    local index
    case "${promotion}" in
        "patch")
            index=2
        ;;

        "minor")
            index=1
        ;;

        "major")
            index=0
        ;;

        "*")
            throwError "Unknown version type to promote: ${promotion}" 2
        ;;
    esac

    version[${index}]=$(( ${version[index]} + 1  ))

    for (( arg=${index} + 1; arg < ${#version[@]}; arg+=1 )); do
        version[${arg}]=0
    done

    echo `joinArray "." ${version[@]}`
}
