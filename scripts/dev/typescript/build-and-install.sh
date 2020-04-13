#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/firebase/core.sh
source ./dev-tools/scripts/node/_source.sh

setErrorOutputFile "$(pwd)/error_message.txt"
BuildFile__watch="$(pwd)/.trash/build/watch.txt"

# shellcheck source=./modules.sh
source "${BASH_SOURCE%/*}/modules.sh"

# shellcheck source=./params.sh
source "${BASH_SOURCE%/*}/params.sh"

# shellcheck source=./help.sh
source "${BASH_SOURCE%/*}/help.sh"

[[ -e ".scripts/setup.sh" ]] && source .scripts/setup.sh
[[ -e ".scripts/signature.sh" ]] && source .scripts/signature.sh

[[ -e ".scripts/modules.sh" ]] && source .scripts/modules.sh

enforceBashVersion 4.4

appVersion=
thunderstormVersion=
modules=()

#################
#               #
#  DECLARATION  #
#               #
#################

function mapModule() {
  function getModulePackageName() {
    local packageName=$(cat package.json | grep '"name":' | head -1 | sed -E "s/.*\"name\".*\"(.*)\",?/\1/")
    echo "${packageName}"
  }

  function getModuleVersion() {
    local version=$(cat package.json | grep '"version":' | head -1 | sed -E "s/.*\"version\".*\"(.*)\",?/\1/")
    echo "${version}"
  }
  local packageName=$(getModulePackageName)
  local version=$(getModuleVersion)
  modulesPackageName+=("${packageName}")
  modulesVersion+=("${version}")
}

function assertNVM() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM Does not exist.. Script should have installed it.. let's figure this out"
  [[ -s ".nvmrc" ]] && return 0

  return 1
}

function signatureThunderstorm() {
  clear
  logVerbose "${Gray}             _____ _                     _                    _                                      ${NoColor}"
  logVerbose "${Gray} -------    |_   _| |__  _   _ _ __   __| | ___ _ __      ___| |_ ___  _ __ _ __ ___    ${Gray}   ------- ${NoColor}"
  logVerbose "${Gray} -------      | | | '_ \| | | | '_ \ / _\` |/ _ \ '__|____/ __| __/ _ \| '__| '_ \` _ \ ${Gray}   ------- ${NoColor}"
  logVerbose "${Gray} -------      | | | | | | |_| | | | | (_| |  __/ | |_____\__ \ || (_) | |  | | | | | |  ${Gray}   ------- ${NoColor}"
  logVerbose "${Gray} -------      |_| |_| |_|\__,_|_| |_|\__,_|\___|_|       |___/\__\___/|_|  |_| |_| |_|  ${Gray}   ------- ${NoColor}"
  logVerbose "${Gray} -------                                                                                ${Gray}   ------- ${NoColor}"
  logVerbose
  sleep 1s
}

function printVersions() {
  logVerbose
  logVerbose "Thunderstorm version: ${thunderstormVersion}"
  logVerbose "App version: ${appVersion}"
  logVerbose

  local format="%-$(($(getMaxLength "${modules[@]}") + 2))s %-$(($(getMaxLength "${modulesPackageName[@]}") + 2))s  %s\n"
  # shellcheck disable=SC2059
  logDebug "$(printf "       ${format}\n" "Folder" "Package" "Version")"

  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local module="${modules[${i}]}"
    local packageName="${modulesPackageName[${i}]}"
    local version="${modulesVersion[${i}]}"
    # shellcheck disable=SC2059
    logVerbose "$(printf "Found: ${format}\n" "${module}" "${packageName}" "v${version}")"
  done
}

function mapModulesVersions() {
  modulesPackageName=()
  modulesVersion=()
  [[ ! "${thunderstormVersion}" ]] && [[ -e "version-thunderstorm.json" ]] && thunderstormVersion=$(getVersionName "version-thunderstorm.json")

  [[ "${newAppVersion}" ]] && appVersion=${newAppVersion}

  if [[ ! "${appVersion}" ]]; then
    local tempVersion=$(getVersionName "version-app.json")
    local splitVersion=(${tempVersion//./ })
    for ((arg = 0; arg < 3; arg += 1)); do
      [[ ! "${splitVersion[${arg}]}" ]] && splitVersion[${arg}]=0
    done
    appVersion=$(joinArray "." ${splitVersion[@]})
  fi

  executeOnModules mapModule
}

function mapExistingLibraries() {
  _modules=()
  local module
  for module in "${modules[@]}"; do
    [[ ! -e "${module}" ]] && continue
    _modules+=("${module}")
  done
  modules=("${_modules[@]}")
}

# Lifecycle
function executeOnModules() {
  local toExecute=${1}

  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local module="${modules[${i}]}"
    local packageName="${modulesPackageName[${i}]}"
    local version="${modulesVersion[${i}]}"
    [[ ! -e "./${module}" ]] && continue

    _pushd "${module}"
    ${toExecute} "${module}" "${packageName}" "${version}"
    _popd
  done
}

function setEnvironment() {
  function copyConfigFile() {
    local filePattern=${1}
    local targetFile=${2}

    local envs=(${@:3})

    for env in ${envs[@]}; do
      local envConfigFile=${filePattern//ENV_TYPE/${env}}
      [[ ! -e "${envConfigFile}" ]] && continue

      logDebug "Setting ${targetFile} from env: ${env}"
      cp "${envConfigFile}" "${targetFile}"
      return 0
    done

    throwError "Could not find a match for target file: ${targetFile} in envs: ${envs[@]}" 2
  }

  logInfo "Setting envType: ${envType}"
  [[ "${fallbackEnv}" ]] && logWarning " -- Fallback env: ${fallbackEnv}"

  copyConfigFile "./.config/firebase-ENV_TYPE.json" "firebase.json" "${envType}" "${fallbackEnv}"
  copyConfigFile "./.config/.firebaserc-ENV_TYPE" ".firebaserc" "${envType}" "${fallbackEnv}"
  if [[ -e "${backendModule}" ]]; then
    logDebug "Setting backend env: ${envType}"
    _pushd "${backendModule}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
    _popd
  fi

  if [[ -e "${frontendModule}" ]]; then
    logDebug "Setting frontend env: ${envType}"
    _pushd "${frontendModule}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
    _popd > /dev/null
  fi

  local firebaseProject="$(getJsonValueForKey .firebaserc default)"
  verifyFirebaseProjectIsAccessible "${firebaseProject}"
  firebase use "${firebaseProject}"
}

function purgeModule() {
  logInfo "Purge module: ${1}"
  deleteDir node_modules
  [[ -e "package-lock.json" ]] && rm package-lock.json
}

function cleanModule() {
  logVerbose
  logDebug "${module} - Cleaning..."
  clearFolder "${outputDir}"
  clearFolder "${outputTestDir}"

  if [[ -e "../${backendModule}" ]] && [[ $(contains "${module}" "${projectLibraries[@]}") ]]; then
    local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    deleteDir "${backendDependencyPath}"
  fi
}

function setupModule() {
  local module=${1}

  function backupPackageJson() {
    cp package.json _package.json
    throwError "Error backing up package.json in module: ${1}"
  }

  function restorePackageJson() {
    trap 'restorePackageJson' SIGINT
    rm package.json
    throwError "Error restoring package.json in module: ${1}"

    mv _package.json package.json
    throwError "Error restoring package.json in module: ${1}"
    trap - SIGINT
  }

  function cleanPackageJson() {
    local i
    for ((i = 0; i < ${#modules[@]}; i += 1)); do
      local dependencyModule=${modules[${i}]}
      local dependencyPackageName="${modulesPackageName[${i}]}"

      [[ "${module}" == "${dependencyModule}" ]] && break
      [[ ! -e "../${dependencyModule}" ]] && continue

      local escapedModuleName=${dependencyPackageName/\//\\/}

      if [[ $(isMacOS) ]]; then
        sed -i '' "/${escapedModuleName}/d" package.json
      else
        sed -i "/${escapedModuleName}/d" package.json
      fi
    done
  }

  backupPackageJson "${module}"
  cleanPackageJson

  if [[ "${install}" ]]; then
    trap 'restorePackageJson' SIGINT
    deleteDir node_modules/@thunderstorm
    deleteFile package-lock.json
    logInfo
    logInfo "Installing ${module}"
    logInfo
    npm install
    throwError "Error installing module"
    trap - SIGINT
  fi

  if [[ "${module}" == "${frontendModule}" ]] && [[ ! -e "./.config/ssl/server-key.pem" ]]; then
    createDir "./.config/ssl"
    bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
  fi

  restorePackageJson "${module}"
}

function linkDependenciesImpl() {
  local module=${1}

  local BACKTO=$(pwd)
  _cd..
  mapModulesVersions
  _cd "${BACKTO}"

  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    [[ "${module}" == "${modules[${i}]}" ]] && break

    [[ $(contains "${modules[${i}]}" "${projectModules[@]}") ]] && break

    local modulePackageName="${modulesPackageName[${i}]}"
    [[ ! "$(cat package.json | grep "${modulePackageName}")" ]] && continue

    logDebug "Linking ${modules[${i}]} (${modulePackageName}) => ${module}"
    local target="$(pwd)/node_modules/${modulePackageName}"
    local origin="$(pwd)/../${modules[${i}]}/${outputDir}"

    createDir "${target}"

    chmod -R 777 "${target}"
    deleteDir "${target}"

    logVerbose "ln -s ${origin} ${target}"
    ln -s "${origin}" "${target}"
    throwError "Error symlink dependency: ${modulePackageName}"

    local moduleVersion="${modulesVersion[${i}]}"
    [[ ! "${moduleVersion}" ]] && continue

    local escapedModuleName=${modulePackageName/\//\\/}
    moduleVersion=$(replaceInText "([0-9]+\\.[0-9]+\\.)[0-9]+" "\10" "${moduleVersion}")
    logVerbose "Updating dependency version to ${modulePackageName} => ${moduleVersion}"

    #        replaceAllInFile "\"${escapedModuleName}\": \".*\"" "\"${escapedModuleName}\": \"~${moduleVersion}\"" package.json
    #    echo sed -i '' -E "s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json

    if [[ $(isMacOS) ]]; then
      sed -i '' -E "s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
    else
      sed -i "s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
    fi
    throwError "Error updating version of dependency in package.json"
  done
}

# for now this is duplicate for the sake of fast dev... need to combine the above and this one
function linkThunderstormImpl() {
  local module=${1}

  [[ ! "${internalThunderstormRefs}" ]] && internalThunderstormRefs=(${thunderstormLibraries[@]})

  local temp=(${modules[@]})
  modules=(${internalThunderstormRefs[@]})
  _pushd "${ThunderstormHome}"
  mapModulesVersions
  _popd
  modules=(${temp[@]})

  local i
  for ((i = 0; i < ${#internalThunderstormRefs[@]}; i += 1)); do
    [[ "${module}" == "${internalThunderstormRefs[${i}]}" ]] && break

    [[ $(contains "${internalThunderstormRefs[${i}]}" "${projectModules[@]}") ]] && break

    local modulePackageName="${modulesPackageName[${i}]}"
    [[ ! "$(cat package.json | grep "${modulePackageName}")" ]] && continue

    logDebug "Linking ${internalThunderstormRefs[${i}]} (${modulePackageName}) => ${module}"
    local target="$(pwd)/node_modules/${modulePackageName}"
    local origin="${ThunderstormHome}/${internalThunderstormRefs[${i}]}/${outputDir}"

    createDir "${target}"

    chmod -R 777 "${target}"
    deleteDir "${target}"

    logVerbose "ln -s ${origin} ${target}"
    ln -s "${origin}" "${target}"
    throwError "Error symlink dependency: ${modulePackageName}"
  done
}

function compileModule() {
  local module=${1}

  logInfo "${module} - Compiling..."
  if [[ $(contains "${module}" ${projectLibraries[@]}) ]]; then
    if [[ "${compileWatch}" ]]; then
      tsc-watch -b -f --onSuccess "bash ../relaunch-backend.sh" &
      echo "${module} $!" >> "${BuildFile__watch}"
    else
      tsc -b -f
      throwError "Error compiling:  ${module}"
    fi
  else
    npm run build
    throwError "Error compiling:  ${module}"
  fi
  # tsc -b -f   ALL Libs
  # tsc-watch -b -f --onSuccess "bash ../hack-backend.sh"    LISTEN ONLY LIBS

  # webpack-build ONLY FRONTEND
  # tsc -b -f   ONLY BACKEND

  throwError "Error compiling:  ${module}"

  cp package.json "${outputDir}"/
  deleteFile .dirty

  if [[ -e "../${backendModule}" ]] && [[ $(contains "${module}" "${projectLibraries[@]}") ]]; then
    local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    createDir "${backendDependencyPath}"
    cp -rf "${outputDir}"/* "${backendDependencyPath}/"
  fi

  logVerbose
  logVerbose "Sorting *.json files: ${module}"
  sort-package-json
  [[ -f tsconfig.json ]] && sort-json tsconfig.json --ignore-case
  [[ -f tsconfig-test.json ]] && sort-json tsconfig-test.json --ignore-case

  if [[ $(contains "${module}" "${thunderstormLibraries[@]}") ]] && [[ "${thunderstormVersion}" ]]; then
    logDebug "Setting version '${thunderstormVersion}' to module: ${module}"
    setVersionName "${thunderstormVersion}"
  fi

  if [[ $(contains "${module}" "${projectModules[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}"
  fi

  copyFileToFolder package.json "${outputDir}"/
}

function lintModule() {
  local module=${1}

  logInfo "${module} - linting..."
  tslint --project tsconfig.json
  throwError "Error while linting:  ${module}"
}

function testModule() {
  local module=${1}

  [[ ! -e "tsconfig-test.json" ]] && return 0

  logInfo "${module} - Running tests..."

  deleteDir "${outputTestDir}"
  tsc -p tsconfig-test.json --outDir "${outputTestDir}"
  throwError "Error while compiling tests in:  ${module}"

  copyFileToFolder package.json "${outputTestDir}/test"
  throwError "Error while compiling tests in:  ${module}"

  tslint --project tsconfig-test.json
  throwError "Error while linting tests in:  ${module}"

  node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}"
  throwError "Error while running tests in:  ${module}"
}

function promoteThunderstorm() {

  function assertRepoIsClean() {
    gitAssertBranch master
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull
  }

  function assertRepoAndSubmodulesAreClean() {
    logDebug "Asserting main repo readiness to promote a version..."
    assertRepoIsClean
    logInfo "Main Repo is ready for version promotion"

    for module in "${thunderstormLibraries[@]}"; do
      [[ ! -e "${module}" ]] && throwError "In order to promote a version ALL thunderstorm packages MUST be present!!!" 2

      _pushd "${module}"
      assertRepoIsClean
      _popd
    done
    logInfo "Submodules are ready for version promotion"
  }

  function deriveVersionType() {
    local _version=${1}
    case "${_version}" in
    "patch" | "minor" | "major")
      echo "${_version}"
      return
      ;;

    "p")
      echo "patch"
      return
      ;;

    *)
      throwError "Bad version type: ${_version}" 2
      ;;
    esac
  }

  local versionFile="version-thunderstorm.json"
  local promotionType="$(deriveVersionType "${promoteThunderstormVersion}")"
  local versionName="$(getVersionName "${versionFile}")"
  thunderstormVersion="$(promoteVersion "${versionName}" "${promotionType}")"

  logInfo "Promoting thunderstorm packages: ${versionName} => ${thunderstormVersion}"

  gitAssertOrigin "${boilerplateRepo}"
  assertRepoAndSubmodulesAreClean

  setVersionName "${thunderstormVersion}" "${versionFile}"
  [[ $(gitAssertTagExists "${thunderstormVersion}") ]] && throwError "Tag already exists: v${thunderstormVersion}" 2

}

function pushThunderstormLibs() {
  for module in "${thunderstormLibraries[@]}"; do
    _pushd "${module}"
    gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "Promoted to: v${thunderstormVersion}"

    gitTag "v${thunderstormVersion}" "Promoted to: v${thunderstormVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"
    _popd
  done

  gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "Promoted infra version to: v${thunderstormVersion}"
  gitTag "libs-v${thunderstormVersion}" "Promoted libs to: v${thunderstormVersion}"
  gitPushTags
  throwError "Error pushing promotion tag"
}

function promoteApps() {
  [[ ! "${newAppVersion}" ]] && throwError "MUST specify a new version for the apps... use --set-version=x.y.z" 2

  appVersion=${newAppVersion}
  logDebug "Asserting repo readiness to promote a version..."
  [[ $(gitAssertTagExists "${appVersion}") ]] && throwError "Tag already exists: v${appVersion}" 2

  gitAssertBranch "${allowedBranchesForPromotion[@]}"
  gitFetchRepo
  gitAssertNoCommitsToPull

  local versionFile=version-app.json
  local versionName=$(getVersionName "${versionFile}")
  logInfo "Promoting Apps: ${versionName} => ${appVersion}"

  setVersionName "${appVersion}" "${versionFile}"

  gitTag "v${appVersion}" "Promoted apps to: v${appVersion}"
  gitPushTags
  throwError "Error pushing promotion tag"
}

function publishThunderstorm() {
  for module in "${thunderstormLibraries[@]}"; do
    _pushd "${module}/${outputDir}"

    logInfo "publishing module: ${module}"
    copyFileToFolder ../package.json .
    npm publish --access public
    throwError "Error publishing module: ${module}"

    _popd
  done
}

function checkImportsModule() {
  local module=${1}

  logInfo "${module} - Checking imports..."
  npx madge --circular --extensions ts ./src/main
  throwError "Error found circular imports:  ${module}"
}

function lifecycleModule() {
  local module=${1}

}

#################
#               #
#   EXECUTION   #
#               #
#################

extractParams "$@"
printDebugParams "${debug}" "${params[@]}"

setLogLevel ${tsLogLevel}

if [[ "${printEnv}" ]]; then
  printNpmPackageVersion typescript
  printNpmPackageVersion tslint
  printNpmPackageVersion firebase-tools
  printNpmPackageVersion sort-package-json

  logDebug "node version: $(node -v)"
  logDebug "npm version: $(npm -v)"
  logDebug "bash version: $(getBashVersion)"
  exit 0
fi

if (("${#modules[@]}" == 0)); then
  [[ "${buildThunderstorm}" ]] && modules+=(${thunderstormLibraries[@]})
  modules+=(${projectLibraries[@]})
  modules+=(${projectModules[@]})
  modules=($(filterDuplicates "${modules[@]}"))
fi

if (("${#libsToRun[@]}" > 0)); then
  modules=(${libsToRun[@]})
fi

mapExistingLibraries
mapModulesVersions
printVersions

installAndUseNvmIfNeeded
executeOnModules lifecycleModule

# BUILD
if [[ "${publish}" ]]; then
  logInfo
  bannerInfo "Promote Thunderstorm"
  promoteThunderstorm
fi

if [[ "${envType}" ]]; then
  logInfo
  bannerInfo "Set Environment"
  setEnvironment
fi

if [[ "${purge}" ]]; then
  logInfo
  bannerInfo "Purge"
  executeOnModules purgeModule
fi

if [[ "${setup}" ]]; then
  logInfo
  bannerInfo "Setup"

  logInfo "Setting up global packages..."
  npm i -g typescript@latest eslint@latest tslint@latest firebase-tools@latest sort-package-json@latest sort-json@latest tsc-watch@latest
  executeOnModules setupModule
fi

if [[ "${linkDependencies}" ]]; then
  logInfo
  bannerInfo "Linking Dependencies"
  if [[ "${ThunderstormHome}" ]] && [[ "${linkThunderstorm}" ]]; then
    executeOnModules linkThunderstormImpl
  else
    executeOnModules linkDependenciesImpl
  fi

  mapModulesVersions
  printVersions
fi

if [[ "${clean}" ]]; then
  logInfo
  bannerInfo "Clean"
  executeOnModules cleanModule
fi

if [[ "${build}" ]]; then
  logInfo
  bannerInfo "Compile"

  executeOnModules compileModule
  logInfo "Project Compiled!!"
fi

if [[ "${lint}" ]]; then
  logInfo
  bannerInfo "Lint"
  executeOnModules lintModule
fi

if [[ "${runTests}" ]] && [[ "${testServiceAccount}" ]]; then
  export GOOGLE_APPLICATION_CREDENTIALS="${testServiceAccount}"
  logInfo
  bannerInfo "Test"
  executeOnModules testModule
fi

if [[ "${checkCircularImports}" ]]; then
  logInfo
  bannerInfo "Checking Circular Imports"
  executeOnModules checkImportsModule
fi

# PRE-Launch and deploy

if [[ "${launchBackend}" ]]; then
  logInfo
  bannerInfo "Launch Backend"

  _pushd "${backendModule}"
  if [[ "${launchFrontend}" ]]; then
    npm run launch &
  else
    npm run launch
  fi
  _popd
fi

if [[ "${launchFrontend}" ]]; then
  logInfo
  bannerInfo "Launch Frontend"

  _pushd "${frontendModule}"
  if [[ "${launchBackend}" ]]; then
    npm run launch &
  else
    npm run launch
  fi
  _popd
fi

# Deploy
if [[ "${deployBackend}" ]] || [[ "${deployFrontend}" ]]; then
  if [[ "${newAppVersion}" ]]; then
    logInfo
    bannerInfo "Promote App"
    promoteApps
  fi

  logInfo
  bannerInfo "deployBackend || deployFrontend"

  [[ ! "${envType}" ]] && throwError "MUST set env while deploying!!" 2

  firebaseProject=$(getJsonValueForKey .firebaserc "default")

  if [[ "${deployBackend}" ]] && [[ -e ${backendModule} ]]; then
    logInfo "Using firebase project: ${firebaseProject}"
    firebase use "${firebaseProject}"
    firebase deploy --only functions
    throwWarning "Error while deploying functions"
  fi

  if [[ "${deployFrontend}" ]] && [[ -e ${frontendModule} ]]; then
    logInfo "Using firebase project: ${firebaseProject}"
    firebase use "${firebaseProject}"
    firebase deploy --only hosting
    throwWarning "Error while deploying hosting"
  fi
fi

# OTHER

if [[ "${publish}" ]]; then
  logInfo
  bannerInfo "Publish"

  publishThunderstorm
  pushThunderstormLibs
  executeOnModules setupModule
  gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "built with new dependencies version"
fi
