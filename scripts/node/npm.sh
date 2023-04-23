#!/bin/bash

npm.verifyPackageInstalledGlobally() {
  local package=${1}
  local minVersion=${2}
  local foundVersion="$(npm.getPackageVersion "${package}")"

  [[ "${foundVersion}" == "${minVersion}" ]] && return 0

  logWarning "Found wrong version '${foundVersion}' of '${package}...'"
  logInfo "Installing required package version: ${package}@${minVersion}"
  npm i -g "${package}@${minVersion}"
}

npm.printPackageVersion() {
  local package=${1}
  logInfo "${package}: $(npm.getPackageVersion "${package}")"
}

npm.getPackageVersion() {
  local package=${1}

  zevel=$(npm list -g "${package}" | grep "${package}" 2>&1)
  local code=$?
  [[ "${code}" != "0" ]] && echo "N/A" && return 1

  local output="${zevel}"
  local foundVersion=$(echo "${output}" | tail -1 | sed -E "s/.*${package}@(.*)/\1/")
  echo "${foundVersion}"
  return 0
}

printNodePackageTree() {
  local module=$(getRunningDir)
  local output=${1}
  logDebug "${module} - Printing dependency tree..."
  folder.create "${output}"
  npm list > "${output}/${module}.txt"
}

npm.queryVersion() {
  local packageName="${1}"
  local version="${2}"
  npm view "${packageName}@${version}" version | tail -1 |  sed -E "s/.*'([0-9.]+)'/\1/"
}