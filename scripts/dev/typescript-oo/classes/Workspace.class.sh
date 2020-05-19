#!/bin/bash
CONST_TS_VER_JSON="version-thunderstorm.json"
CONST_APP_VER_JSON="version-app.json"
Workspace() {

  declare thunderstormVersion
  declare appVersion

  declare -a tsLibs
  declare -a projectLibs
  declare -a active
  declare -a apps
  declare -a allLibs

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

  Workspace.active.forEach() {
    this.forEach "${1}" "${active[*]}" ${@:2}
  }

  Workspace.apps.forEach() {
    this.forEach "${1}" "${apps[*]}" ${@:2}
  }

  Workspace.tsLibs.forEach() {
    this.forEach "${1}" "${tsLibs[*]}" ${@:2}
  }

  _forEach() {
    local command=${1}
    [[ ! "${command}" ]] && throwError "No command spcified" 2
    local items=(${2})

    for item in ${items[@]}; do
      _pushd "$("${item}.folderName")"
      "${item}.${command}" ${@:3}
      throwError "Error executing command: ${item}.${command} ${@:2}"
      _popd
    done
  }

  _printDependencyTree() {
    [[ ! "${ts_dependencies}" ]] && return

    this.active.forEach printDependencyTree
    exit 0
  }

  _prepareToPublish() {
    [[ ! "${ts_publish}" ]] && return

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

    this.active.forEach setEnvironment
  }

  _assertNoCyclicImport() {
    [[ ! "${checkCircularImports}" ]] && return

    logInfo
    bannerInfo "Cyclic Imports"

    this.active.forEach assertNoCyclicImport
  }

  _purge() {
    [[ ! "${ts_purge}" ]] && return

    logInfo
    bannerInfo "Purge"

    this.active.forEach purge
  }

  _clean() {
    [[ ! "${ts_clean}" ]] && return

    logInfo
    bannerInfo "Clean"

    # the second condition can create issues if a lib is added as a projectModule..
    # TODO: Figure this out... in which context should this run??

    this.active.forEach clean
  }

  _install() {
    [[ ! "${ts_install}" ]] && return

    #    logInfo "Installing global packages..."
    #    npm i -g typescript@latest eslint@latest tslint@latest firebase-tools@latest sort-package-json@latest sort-json@latest tsc-watch@latest

    logInfo
    bannerInfo "Install"

    this.active.forEach install ${libraries[@]}
  }

  _link() {
    [[ ! "${ts_link}" ]] && return

    logInfo
    bannerInfo "Link"

    this.active.forEach link ${libraries[@]}
  }

  _compile() {
    [[ ! "${ts_compile}" ]] && return
    logInfo
    bannerInfo "Compile"

    this.active.forEach compile
  }

  _lint() {
    [[ ! "${ts_lint}" ]] && return
    logInfo
    bannerInfo "Lint"

    this.active.forEach lint
  }

  _test() {
    [[ ! "${ts_test}" ]] && return
    [[ ! "${testServiceAccount}" ]] && throwError "MUST specify path to a test service account" 2
    [[ ! -e "${testServiceAccount}" ]] && throwError "Sevice account cannot be resolved from path: ${testServiceAccount}" 2

    export GOOGLE_APPLICATION_CREDENTIALS="${testServiceAccount}"
    logInfo
    bannerInfo "Test"
    this.active.forEach test
  }

  _launch() {
    ((${#ts_launch[@]} == 0)) && return

    logInfo
    bannerInfo "Launch"

    this.apps.forEach launch
  }

  _deploy() {
    ((${#ts_deploy[@]} == 0)) && return

    logInfo
    bannerInfo "Deploy"

    [[ ! "${envType}" ]] && throwError "MUST set env while deploying!!" 2

    this.apps.forEach deploy
  }

  _publish() {
    [[ ! "${ts_publish}" ]] && return

    this.tsLibs.forEach canPublish
    this.tsLibs.forEach publish
    #    gitNoConflictsAddCommitPush "Thunderstorm" "$(gitGetCurrentBranch)" "published version v${thunderstormVersion}"
  }

  _toLog() {
    logVerbose
    logVerbose "Thunderstorm version: ${thunderstormVersion}"
    logVerbose "App version: ${appVersion}"
    logVerbose

    this.active.forEach toLog
  }
}