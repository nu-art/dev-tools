#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/firebase/core.sh
source ./dev-tools/scripts/node/_source.sh

setErrorOutputFile "$(pwd)/error_message.txt"

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
compilerFlags=()

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

  local packageName=$(getModulePackageName)
  modulesPackageName+=("${packageName}")
}

printDependencyTree() {
  local module=${1}
  logDebug "${module} - Printing dependency tree..."
  createDir "../.trash/dependencies"
  npm list > "../.trash/dependencies/${module}.txt"
}

printVersions() {
  logVerbose
  logVerbose "Thunderstorm version: ${thunderstormVersion}"
  logVerbose "App version: ${appVersion}"
  logVerbose

  local format="%-$(($(getMaxLength "${modules[@]}") + 2))s %-$(($(getMaxLength "${modulesPackageName[@]}") + 2))s\n"
  # shellcheck disable=SC2059
  logDebug "$(printf "       ${format}\n" "Folder" "Package")"

  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local module="${modules[${i}]}"
    local packageName="${modulesPackageName[${i}]}"
    # shellcheck disable=SC2059
    logVerbose "$(printf "Found: ${format}\n" "${module}" "${packageName}")"
  done
}

mapModulesVersions() {
  modulesPackageName=()
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
  local _modules=
  if (("${#libsToRun[@]}" > 0)); then
    _modules=(${libsToRun[@]})
  else
    _modules+=(${projectLibraries[@]})
    _modules+=(${projectModules[@]})
    _modules=($(array_filterDuplicates "${_modules[@]}"))
  fi

  local module
  for module in "${_modules[@]}"; do
    [[ ! -e "${module}" ]] && continue
    modules+=("${module}")
  done
}

# Lifecycle
executeOnModules() {
  local toExecute=${1}
  local _modules=(${@:2})
  ((${#_modules[@]} == 0)) && _modules=(${modules[@]})
  echo "${toExecute} - modules: ${_modules[@]}"
  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local module="${modules[${i}]}"
    local packageName="${modulesPackageName[${i}]}"
    [[ ! -e "./${module}" ]] && continue

    _pushd "${module}"
    ${toExecute} "${module}" "${packageName}"
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

  # the second condition can create issues if a lib is added as a projectModule..
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

  trap 'restorePackageJson' SIGINT

  deleteDir node_modules/@intuitionrobotics
  deleteDir node_modules/@nu-art
  deleteFile package-lock.json
  logInfo
  logInfo "Installing ${module}"
  logInfo

  npm install
  throwError "Error installing module"

  if [[ "${module}" == "${frontendModule}" ]] && [[ ! -e "./.config/ssl/server-key.pem" ]]; then
    createDir "./.config/ssl"
    bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
  fi

  trap - SIGINT

  restorePackageJson "${module}"
}

linkDependenciesImpl() {
  local module=${1}

  logVerbose
  logVerbose "Sorting *.json files: ${module}"
  sort-package-json
  copyFileToFolder package.json "${outputDir}"/

  if [[ $(array_contains "${module}" "${thunderstormLibraries[@]}") ]] && [[ "${thunderstormVersion}" ]]; then
    logDebug "Setting version '${thunderstormVersion}' to module: ${module}"
    setVersionName "${thunderstormVersion}" "${outputDir}/package.json"

    #duplicate code cause this is anyway not a good solution.. need to think about this further!!
  elif [[ $(array_contains "${module}" "${projectLibraries[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}" "${outputDir}/package.json"
  elif [[ $(array_contains "${module}" "${projectModules[@]}") ]]; then
    logDebug "Setting version '${appVersion}' to module: ${module}"
    setVersionName "${appVersion}" "${outputDir}/package.json"
  fi

  local i
  for ((i = 0; i < ${#modules[@]}; i += 1)); do
    local libModule=${modules[${i}]}
    [[ "${module}" == "${libModule}" ]] && break

    [[ $(array_contains "${libModule}" "${projectModules[@]}") ]] && break

    local modulePackageName="${modulesPackageName[${i}]}"
    [[ ! "$(cat package.json | grep "${modulePackageName}")" ]] && continue

    logDebug "Linking ${libModule} (${modulePackageName}) => ${module}"
    local target="$(pwd)/node_modules/${modulePackageName}"
    local origin="$(pwd)/../${libModule}/${outputDir}"

    createDir "${target}"

    chmod -R 777 "${target}"
    deleteDir "${target}"

    logVerbose "ln -s ${origin} ${target}"
    ln -s "${origin}" "${target}"
    throwError "Error symlink dependency: ${modulePackageName}"

    if [[ $(array_contains "${libModule}" "${thunderstormLibraries[@]}") ]] && [[ "${thunderstormVersion}" ]]; then
      local moduleVersion="${thunderstormVersion}"
      #duplicate code cause this is anyway not a good solution.. need to think about this further!!
    elif [[ $(array_contains "${libModule}" "${projectLibraries[@]}") ]]; then
      local moduleVersion="${appVersion}"
    elif [[ $(array_contains "${libModule}" "${projectModules[@]}") ]]; then
      local moduleVersion="${appVersion}"
    fi

    [[ ! "${moduleVersion}" ]] && throwError "Could not resolve version for module: ${libModule}"

    local escapedModuleName=${modulePackageName/\//\\/}
    moduleVersion=$(string_replace "([0-9]+\\.[0-9]+\\.)[0-9]+" "\10" "${moduleVersion}")
    logVerbose "Updating dependency version to ${modulePackageName} => ${moduleVersion}"

    #        replaceAllInFile "\"${escapedModuleName}\": \".*\"" "\"${escapedModuleName}\": \"~${moduleVersion}\"" package.json
    #    echo sed -i '' -E \'"s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g"\' "${module}/${outputDir}/package.json"
    if [[ $(isMacOS) ]]; then
      sed -i '' -E "s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" "${outputDir}/package.json"
    else
      sed -i -E "s/\"${escapedModuleName}\": \".[0-9]+\\.[0-9]+\\.[0-9]+\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" "${outputDir}/package.json"
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
        tsc-watch -p ./src/main/tsconfig.json --outDir --rootDir ./src/${folder} "${outputDir}" ${compilerFlags[@]} --onSuccess "bash ../relaunch-backend.sh" &
        echo "${module} ${folder} $!" >> "${CONST_BuildWatchFile}"
      else
        tsc -p "./src/${folder}/tsconfig.json" --rootDir ./src/${folder} --outDir "${outputDir}" ${compilerFlags[@]}
        throwWarning "Error compiling: ${module}/${folder}"
        # figure out the rest of the dirs...
      fi
    done
  else
    npm run build
    throwWarning "Error compiling: ${module}"
  fi

  if [[ -e "../${backendModule}" ]] && [[ $(array_contains "${module}" "${projectLibraries[@]}") ]]; then
    local backendDependencyPath="../${backendModule}/.dependencies/${module}"
    createDir "${backendDependencyPath}"
    cp -rf "${outputDir}"/* "${backendDependencyPath}/"
  fi
}

lintModule() {
  local module=${1}

  logInfo "${module} - linting..."
  _cd src
  local folders=($(listFolders))
  _cd..

  for folder in "${folders[@]}"; do
    [[ "${folder}" == "test" ]] && continue
    if [[ $(array_contains "${module}" ${projectLibraries[@]}) ]]; then
      tslint --project "./src/${folder}/tsconfig.json"
    else
      npm run lint
    fi

    throwError "Error while linting:  ${module}/${folder}"
  done
}

testModule() {
  local module=${1}

  [[ ! -e "./src/test/tsconfig.json" ]] && return 0

  logInfo "${module} - Compiling tests..."
  deleteDir "${outputTestDir}"
  tsc -p ./src/test/tsconfig.json --outDir "${outputTestDir}"
  throwError "Error while compiling tests in:  ${module}"

  copyFileToFolder package.json "${outputTestDir}/test"
  throwError "Error while compiling tests in:  ${module}"

  logInfo "${module} - Linting tests..."
  tslint --project ./src/test/tsconfig.json
  throwError "Error while linting tests in:  ${module}"

  logInfo "${module} - Running tests..."
  node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}"
  throwError "Error while running tests in:  ${module}"
}

promoteThunderstorm() {

  assertRepoIsClean() {
    logDebug "Asserting main repo readiness to promote a version..."
    gitAssertBranch master staging
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull
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
  assertRepoIsClean

  setVersionName "${thunderstormVersion}" "${versionFile}"
  [[ $(gitAssertTagExists "${thunderstormVersion}") ]] && throwError "Tag already exists: v${thunderstormVersion}" 2

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
    if [[ ! -e "${module}/${outputDir}" ]]; then
      logWarning "WILL NOT PUBLISH ${module}.. NOT OUTPUT DIR"
      continue
    fi

    _pushd "${module}/${outputDir}"

    logInfo "publishing module: ${module}"
    npm publish --access public
    throwError "Error publishing module: ${module}"

    _popd
  done

  gitNoConflictsAddCommitPush "Thunderstorm" "$(gitGetCurrentBranch)" "built with new dependencies version"
}

checkImportsModule() {
  local module=${1}

  logInfo "${module} - Checking imports..."
  npx madge --circular --extensions ts ./src/main
  throwError "Error found circular imports:  ${module}"
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
mapExistingLibraries

mapModulesVersions
printVersions

installAndUseNvmIfNeeded

if [[ "${printDependencies}" ]]; then
  executeOnModules printDependencyTree
  exit 0
fi

# BUILD
_publishStart() {
  [[ ! "${publish}" ]] && return

  logInfo
  bannerInfo "Promote Thunderstorm"
  promoteThunderstorm
}

_setEnv() {
  [[ ! "${envType}" ]] && return
  [[ "${envType}" ]] && [[ "${envType}" != "dev" ]] && compilerFlags+=(--sourceMap false)

  logInfo
  bannerInfo "Set Environment"
  setEnvironment
}

_purge() {
  [[ ! "${purge}" ]] && return

  logInfo
  bannerInfo "Purge"
  executeOnModules purgeModule
}

_setup() {
  [[ ! "${setup}" ]] && return

  logInfo
  bannerInfo "Setup"
  logInfo "Setting up global packages..."

  npm i -g typescript@4.1 eslint@latest tslint@latest firebase-tools@latest sort-package-json@latest sort-json@latest tsc-watch@latest
  executeOnModules setupModule
}
_clean() {
  [[ ! "${clean}" ]] && return
  logInfo
  bannerInfo "Clean"
  executeOnModules cleanModule
}

_linkDependencies() {
  [[ ! "${linkDependencies}" ]] && return

  logInfo
  bannerInfo "Linking Dependencies"
  if [[ "${ThunderstormHome}" ]] && [[ "${linkThunderstorm}" ]]; then
    executeOnModules linkThunderstormImpl
  else
    executeOnModules linkDependenciesImpl
  fi

  printVersions
}

_build() {
  [[ ! "${build}" ]] && return
  logInfo
  bannerInfo "Compile"

  executeOnModules compileModule
  logInfo "Project Compiled!!"
}

_lint() {
  [[ ! "${lint}" ]] && return
  logInfo
  bannerInfo "Lint"
  executeOnModules lintModule
}

_tests() {
  [[ ! "${runTests}" ]] && return
  [[ ! "${testServiceAccount}" ]] && return

  export GOOGLE_APPLICATION_CREDENTIALS="${testServiceAccount}"
  logInfo
  bannerInfo "Test"
  executeOnModules testModule
}

if [[ "${checkCircularImports}" ]]; then
  logInfo
  bannerInfo "Checking Circular Imports"
  executeOnModules checkImportsModule
fi

# PRE-Launch and deploy

_launchBackend() {
  [[ ! "${launchBackend}" ]] && return
  logInfo
  bannerInfo "Launch Backend"

  _pushd "${backendModule}"
  if [[ "${launchFrontend}" ]]; then
    npm run launch &
  else
    npm run launch
  fi
  _popd
}
_launchFrontend() {
  [[ ! "${launchFrontend}" ]] && return
  logInfo
  bannerInfo "Launch Frontend"

  _pushd "${frontendModule}"
  if [[ "${launchBackend}" ]]; then
    npm run launch &
  else
    npm run launch
  fi
  _popd
}

# OTHER
_publishEnd() {
  [[ ! "${publish}" ]] && return
  logInfo
  bannerInfo "Publish"

  publishThunderstorm
}

_deploy() {
  [[ ! "${deployBackend}" ]] && [[ ! "${deployFrontend}" ]] && return
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
}

_publishStart
_setEnv
_purge
_setup
_clean
_linkDependencies
_build
_lint
_tests
_launchBackend
_launchFrontend
_publishEnd
_deploy
