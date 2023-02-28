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

checkMinVersion() {
  local _version=${1}
  local _minVersion=${2}

  if [[ ! "${_minVersion}" ]]; then return; fi

  local minVersion=(${_minVersion//./ })
  local version=(${_version//./ })

  for ((arg = 0; arg < ${#minVersion[@]}; arg += 1)); do
    local min="${minVersion[${arg}]}"
    local current="${version[${arg}]}"

    if ((current > min)); then
      echo
      return
    elif ((current == min)); then
      continue
    else
      echo true
    fi
  done
}

promoteVersion() {
  local _version=${1}
  local promotion=${2}
  local version=(${_version//./ })
  local length=${3:-${#version[@]}}
  local index
  case "${promotion}" in
  "patch")
    index=2
    ((length < 3)) && length=3
    ;;

  "minor")
    index=1
    ((length < 2)) && length=2
    ;;

  "major")
    index=0
    ((length < 1)) && length=1
    ;;

  "*")
    throwError "Unknown version type to promote: ${promotion}" 2
    ;;
  esac

  version[${index}]=$((version[index] + 1))

  for ((arg = index + 1; arg < length; arg += 1)); do
    version[${arg}]=0
  done

  for ((arg = length; arg < ${#version[@]}; arg += 1)); do
    version[${arg}]=
  done

  echo "$(string_join "." ${version[@]})"
}

getVersionFileName() {
  local versionFile=${1}

  if [[ ! "${versionFile}" ]]; then
    versionFile=package.json
  fi

  if [[ ! "${versionFile}" ]]; then
    versionFile=version.json
  fi

  if [[ ! -e "${versionFile}" ]]; then
    throwError "No such version file: ${versionFile}" 2
  fi

  echo "${versionFile}"
}

getVersionName() {
  local versionFile=$(getVersionFileName "${1}")
  local version="$(getJsonValueForKey "${versionFile}" "version")"
  [[ ! ${version} ]] && throwError "${1} MUST contain JSON with version property, and value x.y.z" 2
  echo "${version}"
}

getPackageName() {
  local versionFile=$(getVersionFileName "${1}")
  getJsonValueForKey "${versionFile}" "name"
}

setVersionName() {
  local newVersionName=${1}
  local versionFile=$(getVersionFileName "${2}")

  if [[ $(isMacOS) ]]; then
    sed -i '' "s/\"version\": \".*\"/\"version\": \"${newVersionName}\"/g" "${versionFile}"
  else
    sed -i "s/\"version\": \".*\"/\"version\": \"${newVersionName}\"/g" "${versionFile}"
  fi
}

getJsonValueForKey() {
  local fileName=${1}
  local key=${2}

  local value=$(cat "${fileName}" | grep "\"${key}\":" | head -1 | sed -E "s/.*\"${key}\".*\"(.*)\".*/\1/")
  echo "${value}"
}

setJsonValueForKey() {
  local jsonFile=${1}
  local key=${2}
  local value=${3}

  if [[ $(isMacOS) ]]; then
    sed -i '' "s/\"${key}\": \".*\"/\"${key}\": \"${value/"/\\"/}\"/g" "${jsonFile}"
  else
    sed -i "s/\"${key}\": \".*\"/\"${key}\": \"${value/"/\\"/}\"/g" "${jsonFile}"
  fi
}
