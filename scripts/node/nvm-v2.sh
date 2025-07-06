#!/usr/bin/env bash

CONST__FILE_NVMRC=".nvmrc"

## @function: nvm.prepare
## @description: Sources NVM scripts if installed and sets up the environment
nvm.prepare() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}

## @function: nvm.isInstalled
## @description: Checks if NVM is installed by verifying NVM_DIR exists and is valid
## @return: 0 if installed, 1 otherwise
nvm.isInstalled() {
  [[ -z "$NVM_DIR" ]] || [[ ! -e "$NVM_DIR" ]] && return 1
}

## @function: nvm.install(version)
## @description: Installs NVM with the given version (defaults to 0.40.2)
## @param version: Version of NVM to install
nvm.install() {
  local version="${1:-"0.40.2"}"
  echo "Installing NVM v${version}..."
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh" | bash

  local shellRCFile="$HOME/.bashrc"
  [[ -n "$ZSH_VERSION" ]] && shellRCFile="$HOME/.zshrc"
  echo 'export NVM_DIR="$HOME/.nvm"' >> "$shellRCFile"
  echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> "$shellRCFile"
  echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' >> "$shellRCFile"
}

## @function: nvm.requiredVersion
## @description: Reads the required Node version from .nvmrc
## @return: Version string or error if not found
nvm.requiredVersion() {
  [[ ! -e "$CONST__FILE_NVMRC" ]] && echo "Missing .nvmrc" && return 1
  cat "$CONST__FILE_NVMRC" | head -1
}

## @function: nvm.isVersionInstalled(requiredNodeVersion)
## @description: Checks if the given Node version is installed
## @param requiredNodeVersion: Node version to check
## @return: 0 if installed, 1 otherwise
nvm.isVersionInstalled() {
  local requiredNodeVersion="$1"
  [[ -z "$requiredNodeVersion" ]] && requiredNodeVersion="$(nvm.requiredVersion)"
  nvm ls "$requiredNodeVersion" | grep -q "v$requiredNodeVersion" && return 0 || return 1
}

## @function: nvm.installVersion(version)
## @description: Installs the specified Node version
## @param version: Node version to install
nvm.installVersion() {
  local version="$1"
  [[ -z "$version" ]] && version="$(nvm.requiredVersion)"
  echo "Installing Node version $version..."
  nvm install "$version"
}

## @function: nvm.useVersion(version)
## @description: Activates the specified Node version
## @param version: Node version to use
nvm.useVersion() {
  local version="$1"
  [[ -z "$version" ]] && version="$(nvm.requiredVersion)"
  echo "Using Node version $version..."
  nvm use --delete-prefix "v$version" --silent
}

## @function: nvm.installAndUseNvmIfNeeded
## @description: End-to-end setup using .nvmrc - ensures NVM and required Node version are installed and activated
nvm.installAndUseNvmIfNeeded() {
  nvm.prepare
  nvm.isInstalled || nvm.install
  nvm.prepare

  local version="$(nvm.requiredVersion)"
  nvm.isVersionInstalled "$version" || nvm.installVersion "$version"
  nvm.useVersion "$version"
}

## @function: nvm.isolate(label, nodeVersion)
## @description: Creates an isolated install of a Node version under a project label, using a clone and alias
## @param label: Project identifier (e.g., "myproject")
## @param nodeVersion: Base Node version to isolate
nvm.isolate() {
  nvm.prepare

  local label="$1"
  local nodeVersion="$2"
  local src="$NVM_DIR/versions/node/v$nodeVersion"
  local dst="$NVM_DIR/versions/node/v$nodeVersion-$label"

  [[ -z "$nodeVersion" || -z "$label" ]] && echo "Usage: nvm.isolate <label> <nodeVersion>" && return 1

  if [[ ! -d "$dst" ]]; then
    echo "Cloning Node $nodeVersion for '$label'..."
    nvm.isVersionInstalled "$nodeVersion" || nvm.installVersion "$nodeVersion"
    cp -r "$src" "$dst"
  fi

  nvm alias "$label" "v$nodeVersion-$label"
  nvm use "$label"

  if ! command -v pnpm &> /dev/null; then
    echo "Installing pnpm..."
    npm install -g pnpm
  fi
}

## @function: nvm.assert
## @description: Throws error if NVM is not sourced
nvm.assert() {
  type nvm >/dev/null 2>&1 || { echo >&2 "NVM is not loaded"; return 1; }
}

## @function: nvm.activeVersion
## @description: Prints the currently active Node version
nvm.activeVersion() {
  nvm.assert
  nvm current
}
