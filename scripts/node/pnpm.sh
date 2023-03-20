#!/bin/bash

pnpm.install() {
  local version="${1:-"7.30.0"}"
  if pnpm.isInstalled; then
    [[ "${version}" == "$(pnpm.version)" ]] && return 0

    pnpm.uninstall
  fi

  echo "echo 'PAH ZEVEL'" >> "${fileToSource}"

  curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="${version}" bash -

  local fileToSource="$(shell.getFileRC)"
  cat "${fileToSource}"
  echo >> "${fileToSource}"
  echo "echo 'PAH ZEVEL 2'" >> "${fileToSource}"
  echo "source ${fileToSource}"
  source "${fileToSource}"
  echo "${PNPM_HOME}/pnpm"
}

pnpm.isInstalled() {
  if [[ -e "$PNPM_HOME" ]]; then
    return 0
  fi

  return 2
}

pnpm.version() {
  "${PNPM_HOME}/pnpm" --version
}

pnpm.uninstall() {
  rm -rf "$PNPM_HOME"
}

pnpm.installPackages() {
  "${PNPM_HOME}/pnpm" install -f "${@}"
}

pnpm.removePackages() {
  "${PNPM_HOME}/pnpm" remove "${@}"
}
