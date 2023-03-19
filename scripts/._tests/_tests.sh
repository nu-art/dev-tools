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
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/../_core-tools/_source.sh"
CONST_Debug=TRUE

totalSuccess=0
totalErrors=0

assertValue() {
  local expected=${1}
  local actual=${2}

  assert "${expected}" "${actual}"
  result=$?
  [[ ${result} == "1" ]] && logWarning "expected: ${expected} ... but got ${actual}"
}

assert() {
  local expected=${1}
  local actual=${2}

  if [[ "${expected}" == "${actual}" ]]; then
    ((totalSuccess++))
    return 0
  else
    ((totalErrors++))
    return 1
  fi
}

assertCommand() {
  local expected=${1}
  local toEval=${2}
  local prepare=${3}
  local cleanup=${4}
  logDebug "${toEval}"

  local cleanupResult=0
  local prepareResult=0

  if [[ -e ${prepare} ]]; then
    ${prepare}
    prepareResult=$?
    [[ ${prepareResult} != "0" ]] && logError "  fail - to prepare: ${toEval} with error code ${prepareResult}"
  fi

  local actual=$(${toEval})
  assert "${expected}" "${actual}"
  result=$?

  if [[ -e ${cleanup} ]]; then
    ${cleanup}
    cleanupResult=$?
    [[ ${cleanupResult} != "0" ]] && logError "  fail - to cleanup: ${toEval} with error code ${cleanupResult}"
  fi

  if [[ ${prepareResult} == "0" ]] && [[ ${cleanupResult} == "0" ]] && [[ ${result} == "0" ]]; then
    logInfo "   pass - ${toEval} => ${actual}"
  else
    logError "  fail - ${toEval} => ${actual} ... expected: ${expected}"
  fi
}

printSummary() {
  logInfo "Success: ${totalSuccess}"
  ((totalErrors > 0)) && logError "Errors: ${totalErrors}"
}
