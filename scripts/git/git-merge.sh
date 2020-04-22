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

source ${BASH_SOURCE%/*}/_core.sh

runningDir=$(getRunningDir)
projectsToIgnore=("dev-tools")
params=(fromBranch toBranch)
scope="conflict"

extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    "--from="*)
      fromBranch=$(regexParam "--from" "${paramValue}")
      ;;

    "--to="*)
      toBranch=$(regexParam "--to" "${paramValue}")
      ;;

    "--to-this")
      toBranch=$(gitGetCurrentBranch)
      ;;

    "--project" | "-p")
      scope="project"
      ;;

    "--all" | "-a")
      scope="all"
      ;;

    "--external" | "-e")
      scope="external"
      ;;

    "--debug")
      debug="true"
      ;;
    esac
  done
}

printUsage() {
  logVerbose
  logVerbose "   USAGE:"
  logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromBranch} ${toBranch}"
  logVerbose
  exit 0
}

verifyRequirement() {
  local missingParamColor=${BRed}
  local existingParamColor=${BBlue}

  missingData=
  if [[ ! "${fromBranch}" ]]; then
    fromBranch="${missingParamColor}Branch-to-be-merged-from"
    missingData=true
  fi

  if [[ ! "${toBranch}" ]]; then
    toBranch="${missingParamColor}branch-name${NoColor} OR ${missingParamColor}--to-this${NoColor}"
    missingData=true
  fi

  if [[ "${missingData}" ]]; then
    fromBranch=" --from=${existingParamColor}${fromBranch}${NoColor}"
    toBranch=" --to=${existingParamColor}${toBranch}${NoColor}"

    printUsage
  fi
}

extractParams "$@"
verifyRequirement

signature
printCommand "$@"
printDebugParams ${debug} "${params[@]}"

execute() {
  currentBranch=$(gitGetCurrentBranch)
  if [[ "${currentBranch}" != "${toBranch}" ]]; then
    logWarning "Will not merge... expected branch: ${toBranch} but found: ${currentBranch}"
    return
  fi

  gitMerge ${fromBranch}
}

processSubmodule() {
  local mainModule=${1}
  bannerDebug "${mainModule}"

  execute

  local submodules=($(getSubmodulesByScope ${scope} "${projectsToIgnore[@]}"))

  for submodule in "${submodules[@]}"; do
    _cd "${submodule}"
    processSubmodule "${mainModule}/${submodule}"
    _cd..
  done

  local submodules=($(getAllChangedSubmodules "${projectsToIgnore[@]}"))
}

processSubmodule "${runningDir}"
