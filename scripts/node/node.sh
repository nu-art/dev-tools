#!/bin/bash

node.replaceVarsWithValues() {
  local __packageJson=${1:-"./__package.json"}
  local packageJson="$(file.pathToFile "${__packageJson}")/package.json"

  file.delete "${packageJson}" -n
  file.copy "${__packageJson}" "" "${packageJson}" -n

  envVars=()
  envVars+=($(file.findMatches "${packageJson}" '"(\$.*?)"'))

  cleanEnvVar() {
    local length=$((${#1} - 3))
    string.substring "${1}" 2 ${length}
  }

  array.map envVars cleanEnvVar
  array.filterDuplicates envVars

  assertExistingVar() {
    local envVar="${1}"
    local version="${!envVar}"
    [[ "${version}" == "" ]] && throwError "no value defined for version key '${envVar}'" 2
  }

  array.forEach envVars assertExistingVar

  replaceWithVersion() {
    local envVar="${1}"
    local version="${!envVar}"
    file.replaceAll ".${envVar}" "${version}" "${packageJson}" %
  }

  array.forEach envVars replaceWithVersion

  cat "${packageJson}"
}
