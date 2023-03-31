#!/bin/bash

pnpm.install() {
  local version="${1:-"8.1.0"}"
  if pnpm.isInstalled; then
    [[ "${version}" == "$(pnpm.version)" ]] && return 0

    pnpm.uninstall
  fi

  bannerInfo "PNPM - Installing v${version}"
  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="${version}" bash -
  source "$(shell.getFileRC)"
  logInfo "PNPM - Installed"
}

pnpm.isInstalled() {
  [[ -d "${PNPM_HOME}" ]] && return 0
}

pnpm.version() {
  pnpm --version
}

pnpm.uninstall() {
  bannerInfo "PNPM - Uninstalling..."
  rm -rf "${PNPM_HOME}"
  logInfo "PNPM - Uninstalled"
}

pnpm.installPackages() {
  logInfo "PNPM - Installing package"
  pnpm install -f --no-frozen-lockfile "${@}"
}

pnpm.removePackages() {
  pnpm remove "${@}"
}
