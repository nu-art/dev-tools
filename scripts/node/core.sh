#!/bin/bash

verifyNpmPackageInstalledGlobally() {
  local package=${1}
  local minVersion=${2}
  local foundVersion="$(getNpmPackageVersion "${package}")"

  [[ "${code}" != "0" ]] && foundVersion=
  [[ "${foundVersion}" == "${minVersion}" ]] && return 0

  logWarning "Found wrong version '${foundVersion}' of '${package}...'"
  logInfo "Installing required package version: ${package}@${minVersion}"
  npm i -g "${package}@${minVersion}"
  return 1
}

assertNodePackageInstalled() {
  local package=${1}
  verifyNpmPackageInstalledGlobally "${package}"
}

printNpmPackageVersion() {
  local package=${1}
  logInfo "${package}: $(getNpmPackageVersion "${package}")"
}

getNpmPackageVersion() {
  local package=${1}

  zevel=$(npm list -g "${package}" | grep "${package}" 2>&1)
  local code=$?
  [[ "${code}" != "0" ]] && echo "N/A" && return 1

  local output="${zevel}"
  local foundVersion=$(echo "${output}" | tail -1 | sed -E "s/.*${package}@(.*)/\1/")
  echo "${foundVersion}"
  return 0
}

installAndUseNvmIfNeeded() {
  NVM_DIR="$HOME/.nvm"
  if [[ ! -d "${NVM_DIR}" ]]; then
    logInfo
    bannerInfo "Installing NVM"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
  fi

  # shellcheck source=./$HOME/.nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
  if [[ ! $(assertNVM) ]] && [[ "v$(cat .nvmrc | head -1)" != "$(nvm current)" ]]; then

    # shellcheck disable=SC2076
    [[ ! "$(nvm ls | grep "v$(cat .nvmrc | head -1)") | head -1" =~ "v$(cat .nvmrc | head -1)" ]] && echo "nvm install" && nvm install
    nvm use --delete-prefix "v$(cat .nvmrc | head -1)" --silent
    echo "nvm use" && nvm use
  fi
}
