#!/bin/bash

appVersion=
thunderstormVersion=
modules=()
compilerFlags=()

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


promoteThunderstorm() {

  local versionFile="version-thunderstorm.json"
  local versionName="$(getVersionName "${versionFile}")"
  thunderstormVersion="$(promoteVersion "${versionName}" "${promoteThunderstormVersion}")"

  logInfo "Promoting thunderstorm packages: ${versionName} => ${thunderstormVersion}"

  setVersionName "${thunderstormVersion}" "${versionFile}"
  [[ $(gitAssertTagExists "${thunderstormVersion}") ]] && throwError "Tag already exists: v${thunderstormVersion}" 2

}

promoteApps() {
  [[ ! "${newAppVersion}" ]] && return

  logInfo
  bannerInfo "Promote App"
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

#################
#               #
#   EXECUTION   #
#               #
#################

# BUILD

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
