#!/bin/bash

BackendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return
    logInfo "deploying ${folderName}"
    #    ${CONST_Firebase} deploy --only functions
    #    throwWarning "Error while deploying functions"
    logInfo "deployed ${folderName}"
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

  _linkLib() {
    local lib=${1}
    local libFolderName="$("${lib}.folderName")"

    local backendDependencyPath="./.dependencies/${libFolderName}"
    createDir "${backendDependencyPath}"
    cp -rf "../${libFolderName}/${outputDir}"/* "${backendDependencyPath}/"

    this.NodePackage.linkLib "${lib}"
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
