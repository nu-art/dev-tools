#!/bin/bash

FrontendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return
    [[ ! "$(array_contains "${folderName}" "${deployableApps[@]}")" ]] && return

    logInfo "Deploying: ${folderName}"
    ${CONST_Firebase} deploy --only hosting
    throwWarning "Error while deploying hosting"
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

    #    for lib in ${@}; do
    #      [[ "${lib}" == "${_this}" ]] && break
    #      local libPath="$("${lib}.path")"
    #      local libFolderName="$("${lib}.folderName")"
    #      local libPackageName="$("${lib}.packageName")"
    #
    #      [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue
    #
    #      local backendDependencyPath="./.dependencies/${libFolderName}"
    #      createDir "${backendDependencyPath}"
    #      cp -rf "${libPath}/${libFolderName}/${outputDir}"/* "${backendDependencyPath}/"
    #    done
  }

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return

    logInfo "Launching: ${folderName}"
    npm run launch
  }

  _install() {
    if [[ ! -e "./.config/ssl/server-key.pem" ]]; then
      createDir "./.config/ssl"
      bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
    fi

    this.NodePackage.install ${@}
  }

  _link() {

    this.NodePackage.link ${@}

    if [[ "${ts_linkThunderstorm}" ]] && [[ -e "./node_modules/react" ]]; then
      deleteDir "./node_modules/react"
      [[ -e "./node_modules/react}" ]] && rm -if "./node_modules/react"

      origin="${ThunderstormHome}/thunderstorm/node_modules/react"
      target="./node_modules/react"

      logWarning "ln -s ${origin} ${target}"
      ln -s ${origin} ${target}
    fi
  }

  _generate() {
    [[ ! "$(array_contains "${folderName}" "${ts_generate[@]}")" ]] && return

    logInfo "Generating: ${folderName}"
    this.generateColors
    this.generateSVG
    this.generateFonts
  }

  _generateSVG() {
    local _pwd=$(pwd)
    [[ ! -e "${CONST_FrontendIconsPath}" ]] && logDebug "Will not generate ${CONST_FrontendIconsFile}.. folder not found: ${CONST_FrontendIconsPath} " && return

    _pushd "${CONST_FrontendIconsPath}"
    local files=($(ls | grep .*\.svg))

    local declaration=""
    local usage=""
    local usageV4=""
    for file in "${files[@]}"; do
      local varName=$(echo "${file}" | sed -E 's/icon__(.*).svg/\1/')

      declaration="${declaration}\\nimport ${varName}Url, {ReactComponent as ${varName}} from '@res/icons/${file}';"
      usage="${usage}\\n\t${varName}: genIcon(${varName}),"
      usageV4="${usageV4}\\n\t${varName}: genIconV4(${varName}Url),"
    done

    deleteFile "../${CONST_FrontendIconsFile}"
    copyFileToFolder "${_pwd}/../dev-tools/scripts/dev/typescript-oo/templates/${CONST_FrontendIconsFile}" ../
    file_replaceLine "ICONS_DECLARATION" "${declaration}" "../${CONST_FrontendIconsFile}"
    file_replaceLine "ICONS_USAGE" "${usage}" "../${CONST_FrontendIconsFile}"
    file_replaceLine "ICONS_V4_USAGE" "${usageV4}" "../${CONST_FrontendIconsFile}"
    _popd
  }

  _generateColors() {
    local _pwd=$(pwd)
    local colorsFile="${CONST_FrontendColorsPath}/${CONST_FrontendColorsFile}"
    [[ ! -e "${colorsFile}" ]] && logDebug "Will not generate colors... file not found: ${colorsFile} " && return

    local declaration="$(cat "${colorsFile}" | grep -E "^const ")"
    local usage=""
    while IFS= read -r line; do
      local varName=$(echo "${line}" | sed -E 's/^const (.*) ?= ?"(.[0-9a-fA-F]+)";?$/\1/')
      usage="${usage}\\n\t${varName}: (alpha?: number) => calculateColorWithAlpha(${varName}, alpha),"
    done <<< "$declaration"

    deleteFile "${colorsFile}"
    copyFileToFolder "${_pwd}/../dev-tools/scripts/dev/typescript-oo/templates/${CONST_FrontendColorsFile}" "${CONST_FrontendColorsPath}"
    file_replaceLine "COLORS_DECLARATION" "${declaration}" "${colorsFile}"
    file_replaceLine "COLORS_USAGE" "${usage}" "${colorsFile}"
  }

  _generateFonts() {
    local _pwd=$(pwd)
    [[ ! -e "${CONST_FrontendFontsPath}" ]] && logDebug "Will not generate ${CONST_FrontendFontsFile}.. folder not found: ${CONST_FrontendFontsPath} " && return
    _pushd "${CONST_FrontendFontsPath}"
    local files=($(ls | grep .*\.ttf))

    local usage=""
    local varName=""
    for file in "${files[@]}"; do
      varName="${file/-/_}"
      varName="${varName,,}"
      varName=$(echo "${varName}" | sed -E 's/(.*).ttf/\1/')

      usage="${usage}\\n\t${varName}: (text: string, color?: string, size?: number) => fontRenderer(text, '${varName}', color, size),"
    done

    deleteFile "../${CONST_FrontendFontsFile}"
    copyFileToFolder "${_pwd}/../dev-tools/scripts/dev/typescript-oo/templates/${CONST_FrontendFontsFile}" ../
    file_replaceLine "FONTS_USAGE" "${usage}" "../${CONST_FrontendFontsFile}"

    _popd
  }
}
