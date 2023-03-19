#!/bin/bash
FOLDER_Config="${Path_RootRunningDir}/.firebase_config"

BackendPackageV3() {
  extends class NodePackageV3

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_activeLibs[@]}")" ]] && return
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return
    [[ ! "$(array_contains "${folderName}" "${deployableApps[@]}")" ]] && return

    logInfo "Deploying: ${folderName}"
    ${CONST_Firebase} --debug deploy --only functions
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

    [[ -e "${Path_RootRunningDir}/version-app.json" ]] && file.copy "${Path_RootRunningDir}/version-app.json" "./src/main" && file.copy "${Path_RootRunningDir}/version-app.json" "./dist"
    file.copy "./package.json" "${outputDir}"

    for lib in ${@}; do
      [[ "${lib}" == "${_this}" ]] && break
      local libPath="$("${lib}.path")"
      local libFolderName="$("${lib}.folderName")"
      local libPackageName="$("${lib}.packageName")"

      [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue

      local backendDependencyPath="./${outputDir}/.dependencies/${libFolderName}"
      createDir "${backendDependencyPath}"
      cp -rf "${libPath}/${libFolderName}/${outputDir}"/* "${backendDependencyPath}/"

      file_replace "\"${libPackageName}\": \"${APP_VERSION}\"" "\"${libPackageName}\": \"file:.dependencies/${libFolderName}\"" "${outputDir}/package.json" "" "%"

      for projectLib in ${ts_projectLibs[@]}; do
        [[ "${projectLib}" == "${lib}" ]] && break

        local nestedLibFolderName="$("${projectLib}.folderName")"
        local nestedLibPackageName="$("${projectLib}.packageName")"
        [[ ! "$(cat "${backendDependencyPath}/package.json" | grep "${nestedLibPackageName}")" ]] && continue

        file_replace "\"${nestedLibPackageName}\": \"${APP_VERSION}\"" "\"${nestedLibPackageName}\": \"file:.dependencies/${nestedLibFolderName}\"" "${backendDependencyPath}/package.json" "" "%"
      done
    done

    npm run build
    throwWarning "Error compiling: ${folderName}"
  }

  _generate() {
    [[ ! "$(array_contains "${folderName}" "${ts_generate[@]}")" ]] && return

    logInfo "Generating: ${folderName}"
  }

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return

    logInfo "Prepare indexes and rules: ${folderName}"
    if [[ ! -e "${FOLDER_Config}/database.rules.json" ]]; then
      copyFileToFolder "${Path_RootRunningDir}/dev-tools/scripts/dev/typescript-oo/templates/firebase_config/database.rules.json" "${FOLDER_Config}"
    fi

    if [[ ! -e "${FOLDER_Config}/firestore.indexes.json" ]]; then
      copyFileToFolder "${Path_RootRunningDir}/dev-tools/scripts/dev/typescript-oo/templates/firebase_config/firestore.indexes.json" "${FOLDER_Config}"
    fi

    if [[ ! -e "${FOLDER_Config}/firestore.rules" ]]; then
      copyFileToFolder "${Path_RootRunningDir}/dev-tools/scripts/dev/typescript-oo/templates/firebase_config/firestore.rules" "${FOLDER_Config}"
    fi

    if [[ ! -e "${FOLDER_Config}/storage.rules" ]]; then
      copyFileToFolder "${Path_RootRunningDir}/dev-tools/scripts/dev/typescript-oo/templates/firebase_config/storage.rules" "${FOLDER_Config}"
    fi

    logInfo "Launching: ${folderName}"
    if [[ "${ts_debugBackend}" == "--debug" ]]; then
      npm run debug
    else
      npm run launch
    fi
  }

  _clean() {
    this.NodePackageV3.clean
    deleteDir ".dependencies"
  }
}
