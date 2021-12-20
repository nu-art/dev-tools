#!/bin/bash

BackendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return

    logInfo "Deploying: ${folderName}"
    ${CONST_Firebase} deploy --only functions
    throwWarning "Error while deploying functions"
    logInfo "Deployed: ${folderName}"
  }

  _setEnvironment() {
    #    TODO: iterate on all source folders
    logDebug "Setting ${folderName} env: ${envType}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
  }

  _compile() {
    logInfo "Compiling: ${folderName}"

    npm run build
    throwWarning "Error compiling: ${folderName}"

    for lib in ${@}; do
      [[ "${lib}" == "${_this}" ]] && break
      local libPath="$("${lib}.path")"
      local libFolderName="$("${lib}.folderName")"
      local libPackageName="$("${lib}.packageName")"

      [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue

      local backendDependencyPath="./.dependencies/${libFolderName}"
      createDir "${backendDependencyPath}"
      cp -rf "${libPath}/${libFolderName}/${outputDir}"/* "${backendDependencyPath}/"
    done
  }

  _generate() {
    [[ ! "$(array_contains "${folderName}" "${ts_generate[@]}")" ]] && return

    logInfo "Generating: ${folderName}"
  }

  _lint() {
    logInfo "Linting: ${folderName}"

    npm run lint
    throwWarning "Error linting: ${folderName}"
  }

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return

    logInfo "Launching: ${folderName}"
    npm run launch
  }

  _clean() {
    this.NodePackage.clean
    deleteDir ".dependencies"
  }

  _install() {
      local libs=(${@})

      deleteFile package-lock.json
      deleteDir "./node_modules/@nu-art"
      deleteDir "./node_modules/@intuitionrobotics"
      for lib in "${libs[@]}"; do
        [[ "${lib}" == "${_this}" ]] && break

        local libPackageName="$("${lib}.packageName")"
        deleteDir "./node_modules/${libPackageName}"

        local libPath="$("${lib}.path")"
        local libFolderName="$("${lib}.folderName")"
        local backendDependencyPath="./.dependencies/${libFolderName}"

        logInfo "Local Dep Path: ${backendDependencyPath}"
        logInfo "LibPath: ${libPath}"
        logInfo "outputDir: ${outputDir}"

        [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue

        ls ./.dependencies
        deleteDir "${backendDependencyPath}"
        createDir "${backendDependencyPath}"
        cp -rf "${libPath}/${libFolderName}/${outputDir}"/* "${backendDependencyPath}/"
        ls ./.dependencies
        ls ./.dependencies/kaspero-types
      done

      this.link

#      backupPackageJson "${folderName}"
#      cleanPackageJson

      logInfo "Installing: ${folderName}"
      logInfo

      npm install
      throwError "Error installing module"

#      restorePackageJson "${folderName}"
    }
}
