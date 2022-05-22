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

    if [[ -e "~/.zshrc" ]]; then
      echo 'export NVM_DIR="$HOME/.nvm"' >>~/.zshrc
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >>~/.zshrc
      echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >>~/.zshrc
    fi
  fi

  # shellcheck source=./$HOME/.nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
  if [[ ! $(assertNVM) ]] && [[ "v$(cat .nvmrc | head -1)" != "$(nvm current)" ]]; then

    nvm deactivate
    nvm uninstall v16.13.0
    # shellcheck disable=SC2076
    [[ ! "$(nvm ls | grep "v$(cat .nvmrc | head -1)") | head -1" =~ "v$(cat .nvmrc | head -1)" ]] && echo "nvm install" && nvm install
    nvm use --delete-prefix "v$(cat .nvmrc | head -1)" --silent
    echo "nvm use" && nvm use
  fi
}

assertNVM() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM Does not exist.. Script should have installed it.. let's figure this out"
  [[ -s ".nvmrc" ]] && return 0

  return 1
}

printNodePackadeTree() {
  local module=$(getRunningDir)
  local output=${1}
  logDebug "${module} - Printing dependency tree..."
  createDir "${output}"
  npm list >"${output}/${module}.txt"
}
