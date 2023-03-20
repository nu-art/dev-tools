#!/bin/bash

pnpm.install() {
  local version="${1:-"7.30.0"}"
  if pnpm.isInstalled; then
    [[ "${version}" == "$(pnpm.version)" ]] && return 0

    pnpm.uninstall
  fi

  [[ ! -e "${HOME}/.bashrc" ]] && touch "${HOME}/.bashrc"

  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="${version}" bash -

  local fileToSource="$(shell.getFileRC)"
  echo "source ${fileToSource}"
  cat "${fileToSource}"
  source "${fileToSource}"
}

pnpm.isInstalled() {
  if [[ -e "$PNPM_HOME" ]]; then
    return 0
  fi

  return 2
}

pnpm.version() {
  pnpm --version
}

pnpm.uninstall() {
  rm -rf "$PNPM_HOME"
}

pnpm.installPackages() {
  pnpm install -f "${@}"
}

pnpm.removePackages() {
  pnpm remove "${@}"
}
