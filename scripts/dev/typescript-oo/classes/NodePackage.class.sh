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
    packageName="$(getJsonValueForKey "${folderName}/__package.json" "name")"
    if { [[ -e "./${folderName}/.eslintrc.js" ]] && [[ "$(cat "./${folderName}/.eslintrc.js" | grep "FROM DEV-TOOLS")" ]]; } || { [[ ! -e "./${folderName}/.eslintrc.js" ]] && [[ ! -e "./${folderName}/tslint.json" ]]; }; then
      local silent
      [[ -e "./${folderName}/.eslintrc.js" ]] && silent="true"
      file_copyToFolder "${PATH_ESLintConfigFile}" "./${folderName}" ${silent}
    fi
  }

  _checkCyclicImports() {
    logInfo "Cyclic imports: ${folderName}"
    npx madge --image "./imports-${folderName}.svg" --circular ./${outputDir}
  }

  _printDependencyTree() {
    logInfo "Dependencies: ${folderName}"
    folder.create "../.trash/dependencies"
    npm list > "../.trash/dependencies/${folderName}.txt"
  }

  _assertNoCyclicImport() {
    logInfo "Assert Circular Imports: ${folderName}"
    npx madge --circular --extensions ts ./src/main
    throwError "Error found circular imports:  ${module}"
  }

  _purge() {
    logInfo "Purging: ${folderName}"
    folder.delete node_modules
    [[ -e "package-lock.json" ]] && rm package-lock.json
  }

  _install() {
    logInfo "Pre-Installing: ${folderName}"
    node.replaceVarsWithValues
  }

  _link() {
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

    folder.create "${target}"
    folder.delete "${target}"
    logVerbose "ln -s ${origin} ${target}"
    ln -s "${origin}" "${target}"
    throwError "Error symlink dependency: ${libPackageName}"
  }

  _clean() {
    logInfo "Cleaning: ${folderName}"

    [[ ! "${outputTestDir}" ]] && throwError "No test output directory specified" 2
    [[ ! "${outputDir}" ]] && throwError "No output directory specified" 2

    folder.create "${outputDir}"
    folder.clear "${outputDir}"

    folder.create "${outputTestDir}"
    folder.clear "${outputTestDir}"
  }

  _compile() {
    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue
      local rootDir="./src/${folder}"
      local distFolder="${outputDir}"

      local absoluteSourcesFolder="$(pwd)/src/${folder}"
      local absoluteOutputDir="$(pwd)/${distFolder}"

      logInfo "Compiling($(tsc -v)): ${folderName}/${folder}"
      if [[ "${ts_watch}" ]]; then
        local parts=
        for watchLine in "${watchIds[@]}"; do
          parts=(${watchLine[@]})
          [[ "${parts[1]}" == "${folder}" ]] && break
        done

        if [[ -e "./src/${folder}/tsconfig.json" ]]; then
          [[ "${parts[2]}" ]] && execute "pkill -P ${parts[2]}"
          local command="bash ../relaunch-backend.sh ${absoluteSourcesFolder} ${absoluteOutputDir} ${folderName} ${Path_RootRunningDir}"
          tsc-watch -p "./src/${folder}/tsconfig.json" --rootDir "${rootDir}" --outDir "${distFolder}" ${compilerFlags[@]} --onSuccess "${command}" &
          local _pid="${folderName} ${folder} $!"
          logInfo "${_pid}"
          newWatchIds+=("${_pid}")
        fi
      else
        if [[ -e "./src/${folder}/tsconfig.json" ]]; then
          tsc -p "./src/${folder}/tsconfig.json" --rootDir "${rootDir}" --outDir "${distFolder}" ${compilerFlags[@]}
          throwWarning "Error compiling: ${module}/${folder}"
        fi

        folder.copyFile ./package.json "${distFolder}"
      fi
      _cd "${absoluteSourcesFolder}"
      find . -name '*.scss' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      find . -name '*.svg' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      find . -name '*.png' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      find . -name '*.jpg' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      find . -name '*.jpeg' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      _cd-
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
        [[ "$?" == "1" ]] && throwError "Error while ES linting: ${module}/${folder}" 2

      elif [[ -e "tslint.json" ]]; then
        logInfo "Linting: ${folderName}/${folder}"
        tslint --project "./src/${folder}/tsconfig.json"
        throwError "Error while linting: ${module}/${folder}"
      fi
    done
  }

  _generateDocs() {
    logInfo "Generating docs: ${folderName}"

    local entryPoints=()
    [[ -e "./src/main/backend/index.ts" ]] && entryPoints+=("./src/main/backend/index.ts")
    [[ -e "./src/main/frontend/index.ts" ]] && entryPoints+=("./src/main/frontend/index.ts")
    [[ -e "./src/main/index.ts" ]] && entryPoints+=("./src/main/index.ts")
    [[ -e "./src/main/index.tsx" ]] && entryPoints+=("./src/main/index.tsx")
    local tsConfig

    [[ -e "./src/main/tsconfig.json" ]] && tsConfig="./src/main/tsconfig.json"
    [[ -e "./tsconfig.json" ]] && tsConfig="./tsconfig.json"

    echo typedoc --cleanOutputDir --basePath "$(pwd)" --tsconfig "${tsConfig}" --options "${PATH_TypeDocConfigFile}" ${entryPoints[*]}
  }

  _test() {
    [[ ! "$(cat ./package.json | grep "\"run-tests\": \"")" ]] && return 0
    [[ ! -e "./src/test/tsconfig.json" ]] && logVerbose "./src/test/tsconfig.json was not found... skipping test phase" && return 0

    logInfo "${folderName} - Running tests..."

    _cd..
    npm run --prefix "${folderName}" run-tests
    local error=$?
    _cd-
    throwError "Error while running tests in:  ${folderName}" $error
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
