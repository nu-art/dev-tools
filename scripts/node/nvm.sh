CONST__FILE_NVMRC=".nvmrc"

nvm.installAndUseNvmIfNeeded() {
  nvm.prepare
  [[ $(nvm.isInstalled) -ne 0 ]] && nvm.install

  nvm.prepare
  nvm.source

  [[ $(nvm.isVersionInstalled) -ne 0 ]] && nvm.installVersion
  nvm.use
}

nvm.prepare() {
  cd $HOME
  ls
  cd -
  export NVM_DIR="$HOME/.nvm"
}

nvm.isInstalled() {
  [[ ! -d $NVM_DIR ]] && return 1
}

nvm.uninstall() {
  [[ $(nvm.isInstalled) -eq 0 ]] && folder.delete $NVM_DIR
}

# shellcheck disable=SC2120
nvm.install() {
  local version="${1:-"0.35.3"}"

  logInfo
  bannerInfo "NVM - Installing v${version}"

  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh" | bash

  local shellRCFile="$(shell.getFileRC)"
  [[ -e "${shellRCFile}" ]] && [[ "$(cat "${shellRCFile}" | grep 'NVM_DIR')" != "" ]] && return 0

  echo 'export NVM_DIR="$HOME/.nvm"' >> "${shellRCFile}"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> "${shellRCFile}"
  echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> "${shellRCFile}"
  logInfo "NVM - Installed"
}

nvm.source() {
  # shellcheck source=./$HOME/.nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" # This loads nvm
}

nvm.assert() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM - Installation was not found" 404
}

nvm.activeVersion() {
  nvm.assert
  nvm current
}

nvm.requiredVersion() {
  [[ ! -e "${CONST__FILE_NVMRC}" ]] && throwError "NVM - ${CONST__FILE_NVMRC} file was not found" 404
  cat "${CONST__FILE_NVMRC}" | head -1
}

nvm.installVersion() {
  logInfo "NVM - Install required version"
  nvm.assert
  nvm install
}

# shellcheck disable=SC2120
nvm.isVersionInstalled() {
  local requiredNodeVersion="${1}"
  [[ ! "${requiredNodeVersion}" ]] && requiredNodeVersion="$(nvm.requiredVersion)"
  local foundVersion="$(nvm ls | grep "v${requiredNodeVersion}" | head -1)"

  if [[ "${foundVersion}" ]]; then
    return 0
  else
    return 2
  fi
}

nvm.use() {
  logInfo "NVM - Use required version"
  nvm use --delete-prefix "v${requiredNodeVersion}" --silent
  nvm use
}
