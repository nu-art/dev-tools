#!/bin/bash
CONST_TS_VER_JSON="version-thunderstorm.json"
CONST_APP_VER_JSON="version-app.json"
CONST_TS_ENV_FILE=".ts_env"
CONST_Version_Typescript=latest
CONST_Version_ESlint=latest
CONST_Version_FirebaseTools=latest

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

    this.setAppsVersion
    this.setThunderstormVersion

  }

  _setAppsVersion() {
    if [[ ! "${appVersion}" ]]; then
      local tempVersion=$(getVersionName ${CONST_APP_VER_JSON})
      local splitVersion=(${tempVersion//./ })
      for ((arg = 0; arg < 3; arg += 1)); do
        [[ ! "${splitVersion[${arg}]}" ]] && splitVersion[${arg}]=0
      done
      appVersion=$(string_join "." "${splitVersion[@]}")
      return
    fi

    [[ "$(getVersionName "${CONST_APP_VER_JSON}")" == "${appVersion}" ]] && return
    logInfo "Promoting Apps: $(getVersionName "${CONST_APP_VER_JSON}") => ${appVersion}"

    logDebug "Asserting repo readiness to promote a version..."
    [[ "${noGit}" ]] && return
    [[ $(gitAssertTagExists "v${appVersion}") ]] && throwError "Tag already exists: v${appVersion}" 2

    gitAssertBranch "${allowedBranchesForPromotion[@]}"
    gitFetchRepo
    gitAssertRepoClean
    gitAssertNoCommitsToPull
  }

  _setThunderstormVersion() {
    [[ ! "${promoteThunderstormVersion}" ]] && return

    local versionName="$(getVersionName "${CONST_TS_VER_JSON}")"
    thunderstormVersion="$(promoteVersion "${versionName}" "${promoteThunderstormVersion}")"

    logInfo "Promoting thunderstorm packages: ${versionName} => ${thunderstormVersion}"

    logDebug "Asserting repo readiness to promote a version..."

    [[ "${noGit}" ]] && return
    [[ $(gitAssertTagExists "${thunderstormVersion}") ]] && throwError "Tag already exists: v${thunderstormVersion}" 2

    gitAssertBranch "${allowedBranchesForPromotion[@]}"
    gitFetchRepo
    gitAssertRepoClean
    gitAssertNoCommitsToPull
  }

  Workspace.active.forEach() {
    this.forEach "${1}" "${active[*]}" "${@:2}"
  }

  Workspace.apps.forEach() {
    this.forEach "${1}" "${apps[*]}" "${@:2}"
  }

  Workspace.tsLibs.forEach() {
    this.forEach "${1}" "${tsLibs[*]}" "${@:2}"
  }

  _forEach() {
    local command=${1}
    [[ ! "${command}" ]] && throwError "No command specified" 2
    local items=(${2})
    local p="${startFromPackage}"

    for (( ; p < ${#items[@]}; p++)); do
      item=${items[${p}]}
      startFromPackage=${p}
      saveState

      _pushd "$("${item}.path")/$("${item}.folderName")"
      "${item}.${command}" "${@:3}"
      (($? > 0)) && throwError "Error executing command: ${item}.${command}"
      _popd
    done
    startFromPackage=0
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
    if [[ ! "${envType}" ]]; then
      [[ ! -e "${CONST_TS_ENV_FILE}" ]] && throwError "Please run ${0} --set-env=<env>" 2
      envType=$(cat ${CONST_TS_ENV_FILE} | grep -E "env=" | sed -E "s/^env=\"(.*)\"$/\1/")
      [[ ! "${envType}" ]] && envType=dev
      return
    fi

    [[ "${envType}" == "NONE" ]] && return
    [[ "${envType}" ]] && [[ "${envType}" != "dev" ]] && compilerFlags+=(--sourceMap false)

    logInfo
    bannerInfo "Set Environment: ${envType}"
    [[ "${fallbackEnv}" ]] && logWarning " -- Fallback env: ${fallbackEnv}"

    copyConfigFile "./.config/firebase-ENV_TYPE.json" "firebase.json" "${envType}" "${fallbackEnv}"
    copyConfigFile "./.config/.firebaserc-ENV_TYPE" ".firebaserc" "${envType}" "${fallbackEnv}"

    local firebaseProject="$(getJsonValueForKey .firebaserc default)"
    [[ "${firebaseProject}" ]] && $(resolveCommand firebase) login
    [[ "${firebaseProject}" ]] && verifyFirebaseProjectIsAccessible "${firebaseProject}"
    [[ "${firebaseProject}" ]] && $(resolveCommand firebase) use "${firebaseProject}"

    this.apps.forEach setEnvironment
    echo "env=\"${envType}\"" >"${CONST_TS_ENV_FILE}"
    [[ "${fallbackEnv}" ]] && echo "env=\"${fallbackEnv}\"" >>"${CONST_TS_ENV_FILE}"
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

    this.active.forEach clean
  }

  _installGlobalPackages() {
    if [[ "${ts_installGlobals}" ]]; then
      logInfo "Installing global packages..."
      rm -rf /var/lib/jenkins/.nvm/versions/node/v16.13.0/lib/node_modules/.typescript-4f2mhipd
      npm i -g typescript@${CONST_Version_Typescript} eslint@${CONST_Version_ESlint} tslint@latest firebase-tools@${CONST_Version_FirebaseTools} sort-package-json@latest sort-json@latest tsc-watch@latest
      storeFirebasePath
    fi
  }

  _install() {
    if [[ "${ts_installPackages}" ]]; then
      logInfo
      bannerInfo "Install"

      this.active.forEach install "${allLibs[@]}"
    fi
  }

  _link() {
    [[ ! "${ts_link}" ]] && return

    logInfo
    bannerInfo "Link"

    this.active.forEach link "${allLibs[@]}"
  }

  _compile() {
    [[ ! "${ts_compile}" ]] && return
    logInfo
    bannerInfo "Compile"

    this.active.forEach compile "${allLibs[@]}"

    [[ "${ts_watch}" ]] && deleteFile "${CONST_BuildWatchFile}"
    for lib in "${allLibs[@]}"; do
      local length=$("${lib}.newWatchIds.length")
      ((length == 0)) && continue
      for ((watchId = 0; watchId < length; watchId++)); do
        local var="${lib}_newWatchIds[${watchId}]"
        echo -e "${!var}" >> "${CONST_BuildWatchFile}"
      done
    done
  }

  _lint() {
    [[ ! "${ts_lint}" ]] && return
    logInfo
    bannerInfo "Lint"

    this.active.forEach lint
  }

  _test() {
    [[ ! "${ts_runTests}" ]] && return
    [[ ! "${testServiceAccount}" ]] && throwError "MUST specify path to a test service account" 2

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

    logInfo "Deployed Apps: $(getVersionName "${CONST_APP_VER_JSON}") => ${appVersion}"

    [[ "${noGit}" ]] && return

    gitTag "v${appVersion}" "Promoted apps to: v${appVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"

    gitNoConflictsAddCommitPush "Thunderstorm" "$(gitGetCurrentBranch)" "published version v${thunderstormVersion}"
  }

  _publish() {
    [[ ! "${ts_publish}" ]] && return

    logInfo
    bannerInfo "Publish Thunderstorm"

    this.tsLibs.forEach canPublish
    this.tsLibs.forEach publish

    local versionName="$(getVersionName "${CONST_TS_VER_JSON}")"
    logInfo "Promoted thunderstorm packages: ${versionName} => ${thunderstormVersion}"
    setVersionName "${thunderstormVersion}" "${CONST_TS_VER_JSON}"

    [[ "${noGit}" ]] && return

    gitTag "v${thunderstormVersion}" "Promoted thunderstorm to: v${thunderstormVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"

    gitNoConflictsAddCommitPush "Thunderstorm" "$(gitGetCurrentBranch)" "published version v${thunderstormVersion}"
  }

  _generate() {
    ((${#ts_generate[@]} == 0)) && return

    logInfo
    bannerInfo "Generate"

    this.apps.forEach generate
  }

  _toLog() {
    logVerbose
    logVerbose "Thunderstorm version: ${thunderstormVersion}"
    logVerbose "App version: ${appVersion}"
    logVerbose

    this.active.forEach toLog
  }
}
