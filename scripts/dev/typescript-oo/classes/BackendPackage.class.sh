#!/bin/bash

BackendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return

    firebase deploy --only functions
    throwWarning "Error while deploying functions"
  }

  _setEnvironment() {
    #    TODO: iterate on all source folders
    logDebug "Setting ${folderName} env: ${envType}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
  }

  _compile() {
    npm run build
    throwWarning "Error compiling: ${module}"
  }

  _lint() {
    npm run lint
    throwWarning "Error linting: ${module}"
  }

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return
    npm run launch
  }

  _clean() {
    deleteDir ".dependencies"
    this.NodePackage.clean
  }
}
