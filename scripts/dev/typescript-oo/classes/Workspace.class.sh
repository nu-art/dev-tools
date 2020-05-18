#!/bin/bash
CONST_TS_VER_JSON="version-thunderstorm.json"
CONST_APP_VER_JSON="version-app.json"
Workspace() {

  declare thunderstormVersion
  declare appVersion

  declare -a libraries

  _prepare() {
    [[ -e "${CONST_TS_VER_JSON}" ]] && thunderstormVersion=$(getVersionName "${CONST_TS_VER_JSON}")
    [[ "${appVersion}" ]] && return

    local tempVersion=$(getVersionName ${CONST_APP_VER_JSON})
    local splitVersion=(${tempVersion//./ })
    for ((arg = 0; arg < 3; arg += 1)); do
      [[ ! "${splitVersion[${arg}]}" ]] && splitVersion[${arg}]=0
    done
    appVersion=$(string_join "." ${splitVersion[@]})
  }

  Workspace_libraries.forEach() {
    local command=${1}
    [[ ! "${command}" ]] && throwError "No command spcified" 2
    for projectLib in ${libraries[@]}; do
      _pushd "$("${projectLib}.folderName")"
      "${projectLib}.${command}" ${@:2}
      _popd
    done
  }

  Workspace_appLibraries.forEach() {
    local command=${1}
    [[ ! "${command}" ]] && throwError "No command spcified" 2
    for projectLib in ${appLibraries[@]}; do
      _pushd "$("${projectLib}.folderName")"
      "${projectLib}.${command}" ${@:2}
      _popd
    done
  }

  _printDependencyTree() {
    [[ ! "${printDependencies}" ]] && return

    this.libraries.forEach printDependencyTree
    exit 0
  }

  _prepareToPublish() {
    [[ ! "${publish}" ]] && return

    assertRepoIsClean() {
      logDebug "Asserting main repo readiness to promote a version..."
      gitAssertBranch master staging
      gitAssertRepoClean
      gitFetchRepo
      gitAssertNoCommitsToPull
    }

    gitAssertOrigin "${boilerplateRepo}"
    assertRepoIsClean
  }

  _setEnvironment() {
    [[ ! "${envType}" ]] && return
    [[ "${envType}" ]] && [[ "${envType}" != "dev" ]] && compilerFlags+=(--sourceMap false)

    logInfo
    bannerInfo "Set Environment: ${envType}"
    [[ "${fallbackEnv}" ]] && logWarning " -- Fallback env: ${fallbackEnv}"

    local firebaseProject="$(getJsonValueForKey .firebaserc default)"
    verifyFirebaseProjectIsAccessible "${firebaseProject}"
    firebase use "${firebaseProject}"

    copyConfigFile "./.config/firebase-ENV_TYPE.json" "firebase.json" "${envType}" "${fallbackEnv}"
    copyConfigFile "./.config/.firebaserc-ENV_TYPE" ".firebaserc" "${envType}" "${fallbackEnv}"

    this.libraries.forEach setEnvironment
  }

  _assertNoCyclicImport() {
    [[ ! "${checkCircularImports}" ]] && return

    logInfo
    bannerInfo "Cyclic Imports"

    this.libraries.forEach assertNoCyclicImport
  }

  _purge() {
    [[ ! "${purge}" ]] && return

    logInfo
    bannerInfo "Purge"

    this.libraries.forEach purge
  }

  _clean() {
    [[ ! "${clean}" ]] && return

    logInfo
    bannerInfo "Clean"

    # the second condition can create issues if a lib is added as a projectModule..
    # TODO: Figure this out... in which context should this run??

    this.libraries.forEach clean
  }

  _install() {
    [[ ! "${setup}" ]] && return

    #    logInfo "Installing global packages..."
    #    npm i -g typescript@latest eslint@latest tslint@latest firebase-tools@latest sort-package-json@latest sort-json@latest tsc-watch@latest

    logInfo
    bannerInfo "Install"

    this.libraries.forEach install ${libraries[@]}
  }

  _link() {
    logInfo
    bannerInfo "Link"

    this.libraries.forEach link "${thunderstormVersion}" ${libraries[@]}
  }

  _compile() {
    [[ ! "${build}" ]] && return
    logInfo
    bannerInfo "Compile"

    this.libraries.forEach compile
  }

  _lint() {
    [[ ! "${lint}" ]] && return
    logInfo
    bannerInfo "Lint"

    this.libraries.forEach lint
  }

  _test() {
    [[ ! "${runTests}" ]] && return
    [[ ! "${testServiceAccount}" ]] && return

    export GOOGLE_APPLICATION_CREDENTIALS="${testServiceAccount}"
    logInfo
    bannerInfo "Test"
    this.libraries.forEach test
  }

  _deploy() {
    [[ ! "${envType}" ]] && throwError "MUST set env while deploying!!" 2

    logInfo
    bannerInfo "Deploy"

    firebaseProject=$(getJsonValueForKey .firebaserc "default")
    logInfo "Using firebase project: ${firebaseProject}"
  }

  _publish() {
    [[ ! "${publish}" ]] && return

    this.libraries.forEach canPublish
    this.libraries.forEach publish
    #    gitNoConflictsAddCommitPush "Thunderstorm" "$(gitGetCurrentBranch)" "published version v${thunderstormVersion}"
  }

  _toLog() {
    logVerbose
    logVerbose "Thunderstorm version: ${thunderstormVersion}"
    logVerbose "App version: ${appVersion}"
    logVerbose

    this.libraries.forEach toLog
  }

}
