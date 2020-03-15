#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/firebase/core.sh
source ./dev-tools/scripts/node/_source.sh

# shellcheck source=~/.bash_profile
# shellcheck disable=SC1090
#[[ -e "${HOME}/.bash_profile" ]] && source "${HOME}/.bash_profile"

# shellcheck source=./params.sh
source "${BASH_SOURCE%/*}/params.sh"

# shellcheck source=./help.sh
source "${BASH_SOURCE%/*}/help.sh"

[[ -e ".scripts/setup.sh" ]] && source .scripts/setup.sh
[[ -e ".scripts/signature.sh" ]] && source .scripts/signature.sh

# shellcheck source=./modules.sh
source "${BASH_SOURCE%/*}/modules.sh"
[[ -e ".scripts/modules.sh" ]] && source .scripts/modules.sh
enforceBashVersion 4.4

appVersion=
nuArtVersion=
modules=()

#################
#               #
#  DECLARATION  #
#               #
#################

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
  logVerbose "Nu-Art version: ${nuArtVersion}"
  logVerbose "App version: ${appVersion}"
  logVerbose
  local output=$(printf "       %-20s %-25s  %s\n" "Folder" "Package" "Version")
  logDebug "${output}"
  executeOnModules printModule
}

function printModule() {
  local output=$(printf "Found: %-20s %-25s  %s\n" "${1}" "${2}" "v${3}")
  logVerbose "${output}"
}

function mapModulesVersions() {
  modulesPackageName=()
  modulesVersion=()
  [[ ! "${nuArtVersion}" ]] && [[ -e "version-nu-art.json" ]] && nuArtVersion=$(getVersionName "version-nu-art.json")

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

function purgeModule() {
  logInfo "Purge module: ${1}"
  deleteDir node_modules
  [[ -e "package-lock.json" ]] && rm package-lock.json
}

function usingBackend() {
  if [[ ! "${deployBackend}" ]] && [[ ! "${launchBackend}" ]]; then
    echo
    return
  fi

  echo true
}

function usingFrontend() {
  if [[ ! "${deployFrontend}" ]] && [[ ! "${launchFrontend}" ]]; then
    echo
    return
  fi

  echo true
}

function shouldBuildModule() {
  [[ $(usingFrontend) ]] && [[ ! $(usingBackend) ]] && [[ "${module}" == "${backendModule}" ]] && return

  [[ $(usingBackend) ]] && [[ ! $(usingFrontend) ]] && [[ "${module}" == "${frontendModule}" ]] && return

  echo true
}

function cleanModule() {
  logVerbose
  logDebug "${module} - Cleaning..."
  clearFolder "${outputDir}"
  clearFolder "${outputTestDir}"
}

function buildModule() {
  local module=${1}

  [[ ! $(shouldBuildModule "${module}") ]] && return
  [[ "${cleanDirt}" ]] && [[ ! -e ".dirty" ]] && return

  logInfo "${module} - Compiling..."
  npm run build
  throwError "Error compiling:  ${module}"

  cp package.json "${outputDir}"/
  deleteFile .dirty
}

function testModule() {
  local module=${1}

  [[ ! -e "tsconfig-test.json" ]] && return 0
  [[ ! $(shouldBuildModule "${module}") ]] && return 0

  logInfo "${module} - Running tests..."

  deleteDir "${outputTestDir}"
  tsc -p tsconfig-test.json --outDir "${outputTestDir}"
  throwError "Error while compiling tests in:  ${module}"

  tslint --project tsconfig-test.json
  throwError "Error while linting tests in:  ${module}"

  node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}"
  throwError "Error while running tests in:  ${module}"
}

function setVersionImpl() {
  local module=${1}

  logVerbose
  logVerbose "Sorting package json file: ${module}"
  sort-package-json
  [[ -f tsconfig.json ]] && sort-json tsconfig.json --ignore-case
  [[ -f tsconfig-test.json ]] && sort-json tsconfig-test.json --ignore-case

  copyFileToFolder package.json "${outputDir}"/
  logDebug "Linking dependencies sources to: ${module}"
  if [[ $(contains "${module}" "${thunderstormLibraries[@]}") ]] && [[ "${nuArtVersion}" ]]; then
    logDebug "Setting version '${nuArtVersion}' to module: ${module}"
    setVersionName "${nuArtVersion}"
  fi

  if [[ $(contains "${module}" "${projectModules[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}"
  fi
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
    moduleVersion=$(replaceInText "([0-9+]\\.[0-9]+\\.)[0-9]+" "\10" "${moduleVersion}")
    logVerbose "Updating dependency version to ${modulePackageName} => ${moduleVersion}"

    #        replaceAllInFile "\"${escapedModuleName}\": \".*\"" "\"${escapedModuleName}\": \"~${moduleVersion}\"" package.json
    if [[ $(isMacOS) ]]; then
      sed -i '' "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
    else
      sed -i "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
    fi
    throwError "Error updating version of dependency in package.json"
  done
}

# for now this is duplicate for the sake of fast dev... need to combine the above and this one
function linkThunderstormImpl() {
  local module=${1}
  local BACKTO=$(pwd)

  [[ ! "${internalThunderstormRefs}" ]] && internalThunderstormRefs=(${thunderstormLibraries[@]})

  local temp=(${modules[@]})
  modules=(${internalThunderstormRefs[@]})
  _cd "${ThunderstormHome}"
  mapModulesVersions
  _cd "${BACKTO}"
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

function backupPackageJson() {
  cp package.json _package.json
  throwError "Error backing up package.json in module: ${1}"
}

function restorePackageJson() {
  rm package.json
  throwError "Error restoring package.json in module: ${1}"

  mv _package.json package.json
  throwError "Error restoring package.json in module: ${1}"
}

function setupModule() {
  local module=${1}

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
    deleteDir node_modules/@nu-art
    deleteFile package-lock.json
    logInfo
    logInfo "Installing ${module}"
    logInfo
    npm install
    throwError "Error installing module"

    #            npm audit fix
    #            throwError "Error fixing vulnerabilities"
    trap - SIGINT
  fi

  if [[ "${module}" == "${frontendModule}" ]] && [[ ! -e "./.config/ssl/server-key.pem" ]]; then
    createDir "./.config/ssl"
    bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
  fi

  restorePackageJson "${module}"
}

function executeOnModules() {
  local toExecute=${1}
  local async=${2}

  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local module="${modules[${i}]}"
    local packageName="${modulesPackageName[${i}]}"
    local version="${modulesVersion[${i}]}"
    [[ ! -e "./${module}" ]] && continue

    _cd "${module}"
    if [[ "${async}" == "true" ]]; then
      ${toExecute} "${module}" "${packageName}" "${version}" &
    else
      ${toExecute} "${module}" "${packageName}" "${version}"
    fi
    _cd..
  done
}

function getModulePackageName() {
  local packageName=$(cat package.json | grep '"name":' | head -1 | sed -E "s/.*\"name\".*\"(.*)\",?/\1/")
  echo "${packageName}"
}

function getModuleVersion() {
  local version=$(cat package.json | grep '"version":' | head -1 | sed -E "s/.*\"version\".*\"(.*)\",?/\1/")
  echo "${version}"
}

function mapModule() {
  local packageName=$(getModulePackageName)
  local version=$(getModuleVersion)
  modulesPackageName+=("${packageName}")
  modulesVersion+=("${version}")
}

function cloneThunderstormModules() {
  local module
  for module in "${thunderstormLibraries[@]}"; do
    logInfo " * Cloning Submodule : ${module}"
    if [[ ! -e "${module}" ]]; then
      git clone "git@github.com:nu-art-js/${module}.git"
    else
      _cd "${module}"
      git pull
      _cd..
    fi
  done
}

function mergeFromFork() {
  local repoUrl=$(gitGetRepoUrl)
  [[ "${repoUrl}" == "${boilerplateRepo}" ]] && throwError "HAHAHAHA.... You need to be careful... this is not a fork..." 2

  logInfo "Making sure repo is clean..."
  gitAssertRepoClean
  git remote add public "${boilerplateRepo}"
  git fetch public
  git merge public/master
  throwError "Need to resolve conflicts...."

  git submodule update dev-tools
}

function pushNuArt() {
  for module in "${thunderstormLibraries[@]}"; do
    [[ ! -e "${module}" ]] && throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
  done

  for module in "${thunderstormLibraries[@]}"; do
    _cd "${module}"
    gitPullRepo
    gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "${pushNuArtMessage}"
    _cd..
  done
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

function promoteNuArt() {
  local versionFile="version-nu-art.json"
  local promotionType="$(deriveVersionType "${promoteNuArtVersion}")"
  local versionName="$(getVersionName "${versionFile}")"
  nuArtVersion="$(promoteVersion "${versionName}" "${promotionType}")"

  logInfo "Promoting Nu-Art: ${versionName} => ${nuArtVersion}"

  logDebug "Asserting main repo readiness to promote a version..."
  gitAssertBranch master
  gitAssertRepoClean
  gitFetchRepo
  gitAssertNoCommitsToPull
  logInfo "Main Repo is ready for version promotion"

  for module in "${thunderstormLibraries[@]}"; do
    [[ ! -e "${module}" ]] && throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2

    _cd "${module}"
    gitAssertBranch master
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull

    [[ $(gitAssertTagExists "${nuArtVersion}") ]] && throwError "Tag already exists: v${nuArtVersion}" 2
    _cd..
  done

  logInfo "Submodules are ready for version promotion"
  logInfo "Promoting Libs: ${versionName} => ${nuArtVersion}"
  setVersionName "${nuArtVersion}" "${versionFile}"
  executeOnModules setVersionImpl

  for module in "${thunderstormLibraries[@]}"; do
    _cd "${module}"
    gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "Promoted to: v${nuArtVersion}"

    gitTag "v${nuArtVersion}" "Promoted to: v${nuArtVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"
    _cd -
  done

  gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "Promoted infra version to: v${nuArtVersion}"
  gitTag "libs-v${nuArtVersion}" "Promoted libs to: v${nuArtVersion}"
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
  executeOnModules setVersionImpl

  gitTag "v${appVersion}" "Promoted apps to: v${appVersion}"
  gitPushTags
  throwError "Error pushing promotion tag"
}

function publishNuArt() {
  for module in "${thunderstormLibraries[@]}"; do
    _pushd "${module}/${outputDir}"

    logInfo "publishing module: ${module}"
    copyFileToFolder ../package.json .
    npm publish --access public
    throwError "Error publishing module: ${module}"

    _popd
  done
}

function setEnvironment() {
  logInfo "Setting envType: ${envType}"
  [[ "${fallbackEnv}" ]] && logWarning " -- Fallback env: ${fallbackEnv}"

  copyConfigFile "./.config/firebase-ENV_TYPE.json" "firebase.json" "${envType}" "${fallbackEnv}"
  copyConfigFile "./.config/.firebaserc-ENV_TYPE" ".firebaserc" "${envType}" "${fallbackEnv}"
  if [[ -e "${backendModule}" ]]; then
    logDebug "Setting backend env: ${envType}"
    _cd "${backendModule}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
    _cd -
  fi

  if [[ -e "${frontendModule}" ]]; then
    logDebug "Setting frontend env: ${envType}"
    _cd "${frontendModule}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
    _cd - > /dev/null
  fi

  local firebaseProject="$(getJsonValueForKey .firebaserc default)"
  verifyFirebaseProjectIsAccessible "${firebaseProject}"
  firebase use "${firebaseProject}"
}

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

function compileOnCodeChanges() {
  logDebug "Stop all fswatch listeners..."
  killAllProcess fswatch

  pids=()
  local sourceDirs=()
  for module in ${modules[@]}; do
    [[ ! -e "./${module}" ]] && continue
    sourceDirs+=("${module}/src")

    logInfo "Dirt watcher on: ${module}/src => bash build-and-install.sh --flag-dirty=${module}"
    fswatch -o -0 "${module}/src" | xargs -0 -n1 -I{} bash build-and-install.sh --flag-dirty="${module}" &
    pids+=($!)
  done

  logInfo "Cleaning team on: ${sourceDirs[@]} => bash build-and-install.sh --clean-dirt"
  fswatch -o -0 ${sourceDirs[@]} | xargs -0 -n1 -I{} bash build-and-install.sh --clean-dirt &
  pids+=($!)

  for pid in "${pids[@]}"; do
    wait "${pid}"
  done
}

function lintModule() {
  local module=${1}

  logInfo "${module} - linting..."
  tslint --project tsconfig.json
  throwError "Error while linting:  ${module}"
}

#################
#               #
#    PREPARE    #
#               #
#################

# Handle recursive sync execution
if [[ ! "${1}" =~ "dirt" ]]; then
  signature
  printCommand "$@"
fi

if [[ "${dirtyLib}" ]]; then
  touch "${dirtyLib}/.dirty"
  logInfo "flagged ${dirtyLib} as dirty... waiting for cleaning team"
  exit 0
fi
if [[ "${cleanDirt}" ]]; then
  logDebug "Cleaning team is ready, stalling 3 sec for dirt to pile up..."
  sleep 3s
else
  printDebugParams "${debug}" "${params[@]}"
fi

#################
#               #
#   EXECUTION   #
#               #
#################

extractParams "$@"

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

if [[ "${#modules[@]}" == 0 ]]; then
  [[ "${buildThunderstorm}" ]] && modules+=(${thunderstormLibraries[@]})
  modules+=(${projectLibraries[@]})
  modules+=(${projectModules[@]})
fi

if [[ "${mergeOriginRepo}" ]]; then
  logInfo
  bannerInfo "Merge Origin"
  mergeFromFork
  logInfo "Merged from origin boilerplate... DONE"
  exit 0
fi

if [[ "${cloneThunderstorm}" ]]; then
  logInfo
  bannerInfo "Cloning Thunderstorm sources"
  cloneThunderstormModules
fi

mapExistingLibraries
mapModulesVersions

# BUILD
if [[ "${purge}" ]]; then
  logInfo
  bannerInfo "Purge"
  executeOnModules purgeModule
fi

NVM_DIR="$HOME/.nvm"
if [[ ! -d "${NVM_DIR}" ]]; then
  logInfo
  bannerInfo "Installing NVM"

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
fi

# shellcheck source=./$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
if [[ ! $(assertNVM) ]] && [[ "v$(cat .nvmrc | head -1)" != "$(nvm current)" ]]; then

  # shellcheck disable=SC2076
  [[ ! "$(nvm ls | grep "v$(cat .nvmrc | head -1)") | head -1" =~ "v$(cat .nvmrc | head -1)" ]] && echo "nvm install" && nvm install
  nvm use --delete-prefix "v$(cat .nvmrc | head -1)" --silent
  echo "nvm use" && nvm use
fi

if [[ "${setup}" ]]; then
  logInfo
  bannerInfo "Setup"

  logInfo "Setting up global packages..."
  npm i -g typescript@latest eslint@latest tslint@latest firebase-tools@latest sort-package-json@latest sort-json@latest nodemon@latest
  executeOnModules setupModule
fi

if [[ "${envType}" ]]; then
  logInfo
  bannerInfo "Set Environment"
  setEnvironment
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

  executeOnModules setVersionImpl
  executeOnModules buildModule
  logInfo "Project Compiled!!"
fi

if [[ "${lint}" ]]; then
  logInfo
  bannerInfo "Lint"
  executeOnModules lintModule
fi

if [[ "${testServiceAccount}" ]]; then
  logInfo
  bannerInfo "Test"
  executeOnModules testModule
fi

# PRE-Launch and deploy

if [[ "${newAppVersion}" ]]; then
  logInfo
  bannerInfo "Promote App"
  promoteApps
fi

if [[ "${launchBackend}" ]]; then
  logInfo
  bannerInfo "Launch Backend"

  _cd "${backendModule}"
  if [[ "${launchFrontend}" ]]; then
    npm run serve &
  else
    npm run serve
  fi
  _cd..
fi

if [[ "${launchFrontend}" ]]; then
  logInfo
  bannerInfo "Launch Frontend"

  _cd "${frontendModule}"
  if [[ "${launchBackend}" ]]; then
    npm run dev &
  else
    npm run dev
  fi
  _cd..
fi

# Deploy

if [[ "${deployBackend}" ]] || [[ "${deployFrontend}" ]]; then
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

if [[ "${pushNuArtMessage}" ]]; then
  bannerInfo "pushNuArtMessage"
  pushNuArt
fi

if [[ "${promoteNuArtVersion}" ]]; then
  logInfo
  bannerInfo "promoteNuArtVersion"

  gitAssertOrigin "${boilerplateRepo}"
  promoteNuArt
fi

if [[ "${publish}" ]]; then
  logInfo
  bannerInfo "Publish"

  gitAssertOrigin "${boilerplateRepo}"
  publishNuArt
  executeOnModules setupModule
  gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "built with new dependencies version"
fi

if [[ "${listen}" ]]; then
  bannerInfo "listen"

  compileOnCodeChanges
fi
