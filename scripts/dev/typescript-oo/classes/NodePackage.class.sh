#!/bin/bash

NodePackage() {

  declare path
  declare folderName
  declare packageName
  declare version
  declare outputDir
  declare outputTestDir

  _prepare() {
    packageName="$(getJsonValueForKey "${folderName}/package.json" "name")"
  }

  _printDependencyTree() {
    logInfo "Dependencies: ${folderName}"
    createDir "../.trash/dependencies"
    npm list > "../.trash/dependencies/${folderName}.txt"
  }

  _assertNoCyclicImport() {
    logInfo "Assert Circular Imports: ${folderName}"
    npx madge --circular --extensions ts ./src/main
    throwError "Error found circular imports:  ${module}"
  }

  _purge() {
    logInfo "Purging: ${folderName}"
    deleteDir node_modules
    [[ -e "package-lock.json" ]] && rm package-lock.json
  }

  _install() {
    local libs=(${@})

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
      for lib in ${libs[@]}; do
        [[ "${lib}" == "${_this}" ]] && break

        local libPackageName="$("${lib}.packageName")"
        file_replace "^.*${libPackageName}.*$" "" package.json "" "%"
      done
    }

    backupPackageJson "${folderName}"
    cleanPackageJson

    trap 'restorePackageJson' SIGINT

    deleteFile package-lock.json
    logInfo "Installing: ${folderName}"
    logInfo

    npm install
    throwError "Error installing module"

    trap - SIGINT

    restorePackageJson "${folderName}"
  }

  _link() {
    local lib=
    createFolder "${outputDir}"
    copyFileToFolder package.json "${outputDir}"

    logDebug "Setting version '${version}' to module: ${folderName}"
    setVersionName "${version}" "${outputDir}/package.json"

    for lib in ${@}; do
      [[ "${lib}" == "${_this}" ]] && break
      logWarning "libPackageName ${libPackageName}"
      local libPackageName="$("${lib}.packageName")"

      [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue
      local libFolderName="$("${lib}.folderName")"
      local libVersion="$("${lib}.version")"
      logDebug "Linking ${lib} (${libPackageName}) => ${folderName}"
      local target="$(pwd)/node_modules/${libPackageName}"
      local origin="${path}/${libFolderName}/${outputDir}"

      createDir "${target}"
      deleteDir "${target}"
      logVerbose "ln -s ${origin} ${target}"
      ln -s "${origin}" "${target}"
      throwError "Error symlink dependency: ${libPackageName}"

      local moduleVersion="$(string_replace "([0-9]+\\.[0-9]+\\.)[0-9]+" "\10" "${libVersion}")"
      logVerbose "Updating dependency version to ${libPackageName} => ${moduleVersion}"

      file_replaceAll "\"${libPackageName}\": \".0\\.0\\.1\"" "\"${libPackageName}\": \"~${moduleVersion}\"" "${outputDir}/package.json" "%"
      throwError "Error updating version of dependency in package.json"

    done
    return 0
  }

  _clean() {
    logInfo "Cleaning: ${folderName}"

    [[ ! "${outputTestDir}" ]] && throwError "No test output directory specified" 2
    [[ ! "${outputDir}" ]] && throwError "No output directory specified" 2

    createFolder "${outputDir}"
    clearFolder "${outputDir}"

    createFolder "${outputTestDir}"
    clearFolder "${outputTestDir}"
  }

  _compile() {
    local watch=${1}

    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue

      logInfo "Compiling: ${folderName}/${folder}"
      if [[ "${watch}" ]]; then
        tsc-watch -p "./src/${folder}/tsconfig.json" --outDir --rootDir "./src/${folder}" "${outputDir}" ${compilerFlags[@]} --onSuccess "bash ../relaunch-backend.sh" &
        echo "${module} ${folder} $!" >> "${BuildFile__watch}"
      else
        tsc -p "./src/${folder}/tsconfig.json" --rootDir "./src/${folder}" --outDir "${outputDir}" ${compilerFlags[@]}
        throwWarning "Error compiling: ${module}/${folder}"
        # figure out the rest of the dirs...
      fi
    done

    if [[ -e "../${backendModule}" ]] && [[ $(array_contains "${module}" "${projectLibraries[@]}") ]]; then
      local backendDependencyPath="../${backendModule}/.dependencies/${module}"
      createDir "${backendDependencyPath}"
      cp -rf "${outputDir}"/* "${backendDependencyPath}/"
    fi
  }

  _lint() {
    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue

      logInfo "Linting: ${folderName}/${folder}"
      tslint --project "./src/${folder}/tsconfig.json"
      throwError "Error while linting: ${module}/${folder}"
    done
  }

  _test() {
    [[ ! -e "./src/test/tsconfig.json" ]] && return 0

    logInfo "Testing: ${folderName}"

    deleteDir "${outputTestDir}"
    tsc -p ./src/test/tsconfig.json --outDir "${outputTestDir}"
    throwError "Error while compiling tests in:  ${folderName}"

    copyFileToFolder package.json "${outputTestDir}/test"
    throwError "Error while compiling tests in:  ${folderName}"

    logInfo "${folderName} - Linting tests..."
    tslint --project ./src/test/tsconfig.json
    throwError "Error while linting tests in:  ${folderName}"

    logInfo "${folderName} - Running tests..."
    node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}"
    throwError "Error while running tests in:  ${folderName}"
  }

  _canPublish() {
    [[ ! -e "./${outputDir}" ]] && throwError "WILL NOT PUBLISH ${folderName}.. NOT OUTPUT DIR" 2
  }

  _publish() {
    _pushd "./${outputDir}"

    logInfo "Publishing: ${folderName}"
    #    npm publish --access public
    #    throwError "Error publishing: ${folderName}"
    _popd
  }

  _exists() {
    [[ -e "${folderName}" ]] && return 0

    return 1
  }

  _toLog() {
    logDebug "${folderName}: ${packageName}"
  }
}
