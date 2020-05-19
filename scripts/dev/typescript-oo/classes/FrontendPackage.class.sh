#!/bin/bash

FrontendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_include "${folderName}" "${ts_deploy[@]}")" ]] && return

    firebase deploy --only hosting
    throwWarning "Error while deploying hosting"
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
    [[ ! "$(array_include "${folderName}" "${ts_launch[@]}")" ]] && return
    npm run launch
  }

  _install() {
    if [[ ! -e "./.config/ssl/server-key.pem" ]]; then
      createDir "./.config/ssl"
      bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
    fi

    this.NodePackage.install ${@}
  }
}
