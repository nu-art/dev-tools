#!/bin/bash

GradleWorkspace() {
  declare appVersion

  declare -a active
  declare -a apps

  Workspace.active.generateCommand() {
    this.generateCommand "${1}" "${active[*]}" "${@:2}"
  }

  _generateCommand() {
    local command=${1}
    [[ ! "${command}" ]] && throwError "No command specified" 2
    local items=(${2})

    for item in "${items[@]}"; do
      _pushd "$("${item}.path")/$("${item}.folderName")"
      "${item}.${command}" "${@:3}"
      (($? > 0)) && throwError "Error executing command: ${item}.${command}"
      _popd
    done
  }

  _setup() {
    logInfo
    bannerInfo "Setup Workspace"
    [[ ! -e ".scripts/apps.sh" ]] && throwError "Must specify .scripts/apps.sh for project !!" 2
    source .scripts/apps.sh
  }

  _clean() {
    [[ ! "${ts_clean}" ]] && return

    logInfo
    bannerInfo "Clean"

    this.active.forEach clean
  }

  _compile() {
    logInfo "_compile"
  }

  _uninstall() {
    logInfo "_uninstall"
  }

  _install() {
    if [[ ! -e "${outputFolder}" ]]; then
      throwError "Output folder does not exists... Build needed - ${outputFolder}" 2
    fi

    if [[ ! "${pathToApk}" ]]; then
      pathToApk=$(find "${outputFolder}" -name "${apkPattern}")
    fi

    if [[ ! "${pathToApk}" ]]; then
      throwError "Could not find apk in path '${outputFolder}', matching the pattern '${apkPattern}'" 2
    fi
  }

  _launch() {
    logInfo "_launch"
  }

  _dependencies() {
    logInfo "_dependencies"
  }

  _forceStop() {
    logInfo "_forceStop"
  }

  _clearData() {
    logInfo "_forceStop"
  }

  _test() {
    logInfo "_test"
  }

}
