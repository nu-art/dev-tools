#!/bin/bash

NodePackage() {

  declare path
  declare watch
  declare folderName
  declare packageName
  declare version
  declare outputDir
  declare outputTestDir
  declare -a watchIds
  declare -a newWatchIds

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
      for lib in "${libs[@]}"; do
        [[ "${lib}" == "${_this}" ]] && break

        local libPackageName="$("${lib}.packageName")"
        file_replace "^.*${libPackageName}.*$" "" package.json "" "%"
      done
    }

    deleteFile package-lock.json
    deleteDir "./node_modules/@nu-art"
    deleteDir "./node_modules/@intuitionrobotics"
    for lib in "${libs[@]}"; do
      [[ "${lib}" == "${_this}" ]] && break

      local libPackageName="$("${lib}.packageName")"
      deleteDir "./node_modules/${libPackageName}"
    done

    backupPackageJson "${folderName}"
    cleanPackageJson

    trap 'restorePackageJson' SIGINT

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
      local libPackageName="$("${lib}.packageName")"

      [[ ! "$(cat package.json | grep "${libPackageName}")" ]] && continue
      this.linkLib "${lib}"
    done
    return 0
  }

  _linkLib() {
    local lib=${1}
    local libPackageName="$("${lib}.packageName")"
    local libFolderName="$("${lib}.folderName")"
    local libVersion="$("${lib}.version")"
    local libPath="$("${lib}.path")"

    logDebug "Linking ${lib} (${libPackageName}) => ${folderName}"
    local target="$(pwd)/node_modules/${libPackageName}"
    local origin="${libPath}/${libFolderName}/${outputDir}"

    createDir "${target}"
    deleteDir "${target}"
    logVerbose "ln -s ${origin} ${target}"
    ln -s "${origin}" "${target}"
    throwError "Error symlink dependency: ${libPackageName}"

    local moduleVersion="$(string_replace "([0-9]+\\.[0-9]+\\.)[0-9]+" "\10" "${libVersion}")"
    logVerbose "Updating dependency version to ${libPackageName} => ${moduleVersion}"

    logInfo "libPackageName: ${libPackageName}"
    logInfo "moduleVersion: ${moduleVersion}"
    logInfo "outputDir: ${outputDir}"
    logInfo "pwd: $(pwd)"

    local match="\"${libPackageName}\": \".0\\.0\\.1\""
    local replacement="\"${libPackageName}\": \"~${moduleVersion}\""
    file_replaceAll "${match}" "${replacement}" "${outputDir}/package.json" "%"
    throwError "Error updating version of dependency in package.json"
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

  _copySecrets() {
    return 0
  }

  _compile() {
    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue
      logInfo "Compiling($(tsc -v)): ${folderName}/${folder}"
      if [[ "${ts_watch}" ]]; then

        local parts=
        for watchLine in "${watchIds[@]}"; do
          parts=(${watchLine[@]})
          [[ "${parts[1]}" == "${folder}" ]] && break
        done

        [[ "${parts[2]}" ]] && execute "pkill -P ${parts[2]}"

        tsc-watch -p "./src/${folder}/tsconfig.json" --rootDir "./src/${folder}" --outDir "${outputDir}" ${compilerFlags[@]} --onSuccess "bash ../relaunch-backend.sh" &

        local _pid="${folderName} ${folder} $!"
        logInfo "${_pid}"
        newWatchIds+=("${_pid}")
      else
        tsc -p "./src/${folder}/tsconfig.json" --rootDir "./src/${folder}" --outDir "${outputDir}" ${compilerFlags[@]}
        throwWarning "Error compiling: ${module}/${folder}"
        # figure out the rest of the dirs...
      fi
    done
  }

  _lint() {
    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue

      if [[ -e ".eslintrc.js" ]]; then
        logInfo "ES Linting: ${folderName}/${folder}"
        eslint --ext .ts --ext .tsx "./src/${folder}"
        throwError "Error while ES linting: ${module}/${folder}"

      elif [[ -e "tslint.json" ]]; then
        logInfo "Linting: ${folderName}/${folder}"
        tslint --project "./src/${folder}/tsconfig.json"
        throwError "Error while linting: ${module}/${folder}"
      fi
    done
  }

  _test() {
    [[ ! -e "./src/test/tsconfig.json" ]] && logVerbose "./src/test/tsconfig.json was not found... skipping test phase" && return 0
    [[ "${testServiceAccount}" ]] && [[ ! -e "${testServiceAccount}" ]] && throwError "Service account cannot be resolved from path: ${testServiceAccount}" 2

    export GOOGLE_APPLICATION_CREDENTIALS="${testServiceAccount}"
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

    local testsToRun=()
    for testToRun in "${ts_testsToRun[@]}"; do
      testsToRun+=("--test=${testToRun}")
    done
    node "${outputTestDir}/test/test" "--service-account=${testServiceAccount}" "${testsToRun[@]}"
    throwError "Error while running tests in:  ${folderName}"
  }

  _canPublish() {
    [[ ! -e "./${outputDir}" ]] && throwError "WILL NOT PUBLISH ${folderName}.. NOT OUTPUT DIR" 2
  }

  _publish() {
    _pushd "./${outputDir}"

    logInfo "Publishing: ${folderName}"
    npm publish --access public
    throwError "Error publishing: ${folderName}"
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
