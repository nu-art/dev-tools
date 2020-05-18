#!/bin/bash

BackendPackage() {
  extends class NodePackage

  _deploy() {
    firebase deploy --only functions
    throwWarning "Error while deploying functions"
  }

  #
  #  -- extends AppPackage
  #

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
    npm run launch
  }

  _clean() {

    local libs=(${@})
    for lib in ${libs[@]}; do
      [[ "${lib}" == "${_this}" ]] && break
    #   local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    #   deleteDir "${backendDependencyPath}"
    done

    this.NodePackage.clean
  }
}
