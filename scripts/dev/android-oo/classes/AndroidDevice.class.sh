#!/bin/bash

AndroidDevice() {

  declare serial
  declare status
  declare errorFileName

  _adbShell() {
    local command="${1}"
    local message="${2}"
    execute "${adbCommand} -s ${serial} shell ${command}" "${message}"
  }

  _adb() {
    local command="${1}"
    local message="${2}"
    execute "${adbCommand} -s ${serial} ${command}" "${message}"
  }

  _waitForDevice() {
    logInfo "_waitForDevice" ${@}
  }

  _installApp() {
    local app=${1}
    this.waitForDevice

    local appName="$("${app}.name")"
    local pathToApk="$("${app}.pathToApk")"
    local targetApkName="${appName}-app.apk"
    local pathToTargetApkName="/data/local/tmp/${targetApkName}"

    logVerbose
    this.adb "push ${pathToApk} ${pathToTargetApkName}" "Copy ${appName} apk onto device: ${pathToTargetApkName}" 2> "${errorFileName}"
    logVerbose
    this.adbShell "pm install -r -d  ${pathToTargetApkName}" "Installing ${appName} apk onto device: ${pathToTargetApkName}" true 2> "${errorFileName}"

    #    local output=$(cat "${errorFileName}")
    deleteFile "${errorFileName}"
    #    retry "${output}" "installAppOnDevice ${serial}" "uninstallFromDevice ${serial}" "COULD NOT INSTALL APP"
  }

  _uninstallApp() {
    local app=${1}
    this.adb "uninstall $("${app}.packageName")" "Uninstalling '$("${app}.name")'..."
  }

  _forceStopApp() {
    local app=${1}
    this.adbShell "am force-stop $("${app}.packageName")" "Force stopping '$("${app}.name")'..."
  }

}
