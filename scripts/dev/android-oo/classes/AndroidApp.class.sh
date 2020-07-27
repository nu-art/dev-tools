#!/bin/bash

AndroidApp() {

  declare name
  declare path
  declare packageName
  declare launcherClass
  declare apkPattern
  declare outputFolder

  declare buildType
  declare flavor

  declare pathToApk

  _clean() {
    logInfo "_clean"
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
