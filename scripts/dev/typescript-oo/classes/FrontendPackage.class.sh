#!/bin/bash

FrontendPackage() {
  extends class NodePackage

  _deploy() {
    firebase deploy --only hosting
    throwWarning "Error while deploying hosting"
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

  _install() {
    if [[ ! -e "./.config/ssl/server-key.pem" ]]; then
      createDir "./.config/ssl"
      bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
    fi

    this.super.install
  }

  _super.install() {
    local libs=(${@})

    backupPackageJson() {
      cp package.json _package.json
      throwError "Error backing up package.json in module: ${1}"
    }

    restorePackageJson() {
      trap 'restorePackageJson' SIGINT
      rm package.json
      throwError "Error restoring package.json in module: ${1}"

      mv _package.json package.json
      throwError "Error restoring package.json in module: ${1}"
      trap - SIGINT
    }

    cleanPackageJson() {
      local i
      for ((i = 0; i < ${#libs[@]}; i += 1)); do
        local lib=${libs[${i}]}
        local libPackageName="$("${lib}.packageName")"

        [[ "${lib}" == "${_this}" ]] && break
        file_replace "^.*${libPackageName}.*$" "" package.json "" "%"
      done
    }

    backupPackageJson "${folderName}"
    cleanPackageJson

    trap 'restorePackageJson' SIGINT

    deleteDir node_modules/@nu-art
    deleteFile package-lock.json
    logInfo "Installing: ${folderName}"
    logInfo

    npm install
    throwError "Error installing module"
    trap - SIGINT

    restorePackageJson "${folderName}"
  }
}
