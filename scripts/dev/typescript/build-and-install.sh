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

mapModule() {
  getModulePackageName() {
    local packageName=$(cat package.json | grep '"name":' | head -1 | sed -E "s/.*\"name\".*\"(.*)\",?/\1/")
    echo "${packageName}"
  }

  getModuleVersion() {
    local version=$(cat package.json | grep '"version":' | head -1 | sed -E "s/.*\"version\".*\"(.*)\",?/\1/")
    echo "${version}"
  }
  local packageName=$(getModulePackageName)
  local version=$(getModuleVersion)
  modulesPackageName+=("${packageName}")
  modulesVersion+=("${version}")
}

assertNVM() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM Does not exist.. Script should have installed it.. let's figure this out"
  [[ -s ".nvmrc" ]] && return 0

  return 1
}

printVersions() {
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

mapModulesVersions() {
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
    appVersion=$(string_join "." ${splitVersion[@]})
  fi

  executeOnModules mapModule
}

mapExistingLibraries() {
  _modules=()
  local module
  for module in "${modules[@]}"; do
    [[ ! -e "${module}" ]] && continue
    _modules+=("${module}")
  done
  modules=("${_modules[@]}")
}

# Lifecycle
executeOnModules() {
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

setEnvironment() {
  copyConfigFile() {
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

purgeModule() {
  logInfo "Purge module: ${1}"
  deleteDir node_modules
  [[ -e "package-lock.json" ]] && rm package-lock.json
}

cleanModule() {
  logVerbose
  logDebug "${module} - Cleaning..."
  clearFolder "${outputDir}"
  clearFolder "${outputTestDir}"

  if [[ -e "../${backendModule}" ]] && [[ $(array_contains "${module}" "${projectLibraries[@]}") ]]; then
    local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    deleteDir "${backendDependencyPath}"
  fi
}

setupModule() {
  local module=${1}

  backupPackageJson() {
    cp package.json _package.json
    throwError "Error backing up package.json in module: ${1}"
  }

  restorePackageJson() {
    trap 'restorePackageJson' SIGINT
    rm package.json
    throwError "Error restoring package.json in module: ${1}"

    mv _package.json package.json
    throwError "Error restoring package.json in module: ${1}"
    trap - SIGINT
  }

  cleanPackageJson() {
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

linkDependenciesImpl() {
  local module=${1}

  local BACKTO=$(pwd)
  _cd..
  mapModulesVersions
  _cd "${BACKTO}"

  if [[ $(array_contains "${module}" "${thunderstormLibraries[@]}") ]] && [[ "${thunderstormVersion}" ]]; then
    logDebug "Setting version '${thunderstormVersion}' to module: ${module}"
    setVersionName "${thunderstormVersion}"
  elif [[ $(array_contains "${module}" "${projectModules[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}"
  fi

  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    [[ "${module}" == "${modules[${i}]}" ]] && break

    [[ $(array_contains "${modules[${i}]}" "${projectModules[@]}") ]] && break

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
    moduleVersion=$(string_replace "([0-9]+\\.[0-9]+\\.)[0-9]+" "\10" "${moduleVersion}")
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
linkThunderstormImpl() {
  local module=${1}

  [[ ! "${internalThunderstormRefs}" ]] && internalThunderstormRefs=(${thunderstormLibraries[@]})

  if [[ $(array_contains "${module}" "${projectModules[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}"
  fi

  local temp=(${modules[@]})
  modules=(${internalThunderstormRefs[@]})
  _pushd "${ThunderstormHome}"
  mapModulesVersions
  _popd
  modules=(${temp[@]})

  local i
  for ((i = 0; i < ${#internalThunderstormRefs[@]}; i += 1)); do
    [[ "${module}" == "${internalThunderstormRefs[${i}]}" ]] && break

    [[ $(array_contains "${internalThunderstormRefs[${i}]}" "${projectModules[@]}") ]] && break

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

compileModule() {
  local module=${1}

  logInfo "${module} - Compiling..."
  if [[ $(array_contains "${module}" ${projectLibraries[@]}) ]]; then
    _cd src
    local folders=($(listFolders))
    _cd..
    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue

      if [[ "${compileWatch}" ]]; then
        tsc-watch -p ./src/main/tsconfig.json --outDir "${outputDir}" --onSuccess "bash ../relaunch-backend.sh" &
        echo "${module} ${folder} $!" >> "${BuildFile__watch}"
      else

        tsc -p "./src/${folder}/tsconfig.json" --outDir "${outputDir}"
        # figure out the rest of the dirs...
      fi

    done
  else
    npm run build
  fi

  throwWarning "Error compiling:  ${module}"

  cp package.json "${outputDir}"/
  deleteFile .dirty

  if [[ -e "../${backendModule}" ]] && [[ $(array_contains "${module}" "${projectLibraries[@]}") ]]; then
    local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    createDir "${backendDependencyPath}"
    cp -rf "${outputDir}"/* "${backendDependencyPath}/"
  fi

  logVerbose
  logVerbose "Sorting *.json files: ${module}"
  sort-package-json
  [[ -f tsconfig.json ]] && sort-json tsconfig.json --ignore-case
  [[ -f tsconfig-test.json ]] && sort-json tsconfig-test.json --ignore-case

  copyFileToFolder package.json "${outputDir}"/
}

lintModule() {
  local module=${1}

  logInfo "${module} - linting..."
  tslint --project tsconfig.json
  throwError "Error while linting:  ${module}"
}

testModule() {
  local module=${1}

  [[ ! -e "./src/test/tsconfig.json" ]] && return 0

  logInfo "${module} - Compinling tests..."
  deleteDir "${outputTestDir}"
  tsc -p ./src/test/tsconfig.json --outDir "${outputTestDir}"
  throwError "Error while compiling tests in:  ${module}"

  copyFileToFolder package.json "${outputTestDir}/test"
  throwError "Error while compiling tests in:  ${module}"

  logInfo "${module} - Linting tests..."
  tslint --project tsconfig-test.json
  throwError "Error while linting tests in:  ${module}"

  logInfo "${module} - Running tests..."
  node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}"
  throwError "Error while running tests in:  ${module}"
}

promoteThunderstorm() {

  assertRepoIsClean() {
    gitAssertBranch master staging
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull
  }

  assertRepoAndSubmodulesAreClean() {
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

  deriveVersionType() {
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

pushThunderstormLibs() {
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

promoteApps() {
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

publishThunderstorm() {
  for module in "${thunderstormLibraries[@]}"; do
    _pushd "${module}/${outputDir}"

    logInfo "publishing module: ${module}"
    copyFileToFolder ../package.json .
    npm publish --access public
    throwError "Error publishing module: ${module}"

    _popd
  done
}

checkImportsModule() {
  local module=${1}

  logInfo "${module} - Checking imports..."
  npx madge --circular --extensions ts ./src/main
  throwError "Error found circular imports:  ${module}"
}

lifecycleModule() {
  local module=${1}

}

#################
#               #
#   EXECUTION   #
#               #
#################

signature
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
  modules=($(array_filterDuplicates "${modules[@]}"))
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

# OTHER

if [[ "${publish}" ]]; then
  logInfo
  bannerInfo "Publish"

  publishThunderstorm
  pushThunderstormLibs
  gitNoConflictsAddCommitPush "${module}" "$(gitGetCurrentBranch)" "built with new dependencies version"
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
