#!/bin/bash

pnpm.install() {
  local version="${1:-"7.29.1"}"
  if pnpm.isInstalled; then
    [[ "${version}" == "$(pnpm.version)" ]] && return 0

    pnpm.uninstall
  fi

  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="${version}" sh -
  source "$(shell.getFileRC)"
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
