#!/bin/bash

pnpm.install() {
  local version="${1:-"8.7.0"}"

  if [[ $(pnpm.isInstalled) -eq 0 ]]; then
    [[ "${version}" == "$(pnpm.version)" ]] && return 0

    pnpm.uninstall
  fi

  bannerInfo "PNPM - Installing v${version}"
  wget -qO- https://get.pnpm.io/install.sh | env PNPM_VERSION="${version}" bash -
  source "$(shell.getFileRC)"
  logInfo "PNPM - Installed"
}

pnpm.isInstalled() {
  [[ -d "${PNPM_HOME}" ]] && return 0
}

pnpm.version() {
  if [[ -x "$(command -v pnpm)" ]]; then
    pnpm --version
  fi
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
