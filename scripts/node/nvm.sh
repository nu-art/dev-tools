CONST__FILE_NVMRC=".nvmrc"

nvm.installAndUseNvmIfNeeded() {
  nvm.prepare
  [[ $(nvm.isInstalled) != "true" ]] && nvm.install

  nvm.prepare
  nvm.source

  [[ $(nvm.isVersionInstalled) != "true" ]] && nvm.installVersion
  nvm.use
}

nvm.prepare() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

nvm.isInstalled() {
  [[ -z "$NVM_DIR" ]] || [[ ! -e "$NVM_DIR" ]] && return 1
}

nvm.uninstall() {
  [[ $(nvm.isInstalled) == "true" ]] && folder.delete "${NVM_DIR}"
}

# shellcheck disable=SC2120
nvm.install() {
  local version="${1:-"0.40.2"}"

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

  [[ "${foundVersion}" ]] && echo "true"
}

nvm.use() {
  logInfo "NVM - Use required version"
  logWarning "  nvm use --delete-prefix \"v${requiredNodeVersion}\" --silent"
  nvm use --delete-prefix "v${requiredNodeVersion}" --silent
  nvm use
}

## @function: nvm.isolate(label, ...nodeVersion)
##
## @description: clone a node version folder and give it an alias
##

nvm.isolate() {
  nvm.prepare

  local label="$1"
  local nodeVersion="$2"
  local src="$NVM_DIR/versions/node/v$nodeVersion"
  local dst="$NVM_DIR/versions/node/v$nodeVersion-$label"

  # Check if nvm is installed, if not install it
  if [ -z "$NVM_DIR" ] || [ ! -e "$NVM_DIR" ]; then
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh | bash
  fi

  if [[ ${freshStart} ]]; then
    rm -rf "$dst"
  fi

  if [ ! -d "$dst" ]; then
    echo "Cloning Node $nodeVersion for project '$label'..."
    nvm install
    mv "$src" "$dst"
  fi

  # Install the required Node.js version

  echo "Creating alias '$label'..."
  nvm alias "$label" "v$nodeVersion-$label"
  nvm use "$label"

  # Check if pnpm is installed, if not install it
  if ! command -v pnpm &> /dev/null; then
    echo "Installing pnpm..."
    npm install -g pnpm
  fi
}