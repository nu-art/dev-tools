#!/bin/bash

NodePackageV2() {

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
    if { [[ -e "./${folderName}/.eslintrc.js" ]] && [[ "$(cat "./${folderName}/.eslintrc.js" | grep "FROM DEV-TOOLS")" ]]; } || { [[ ! -e "./${folderName}/.eslintrc.js" ]] && [[ ! -e "./${folderName}/tslint.json" ]]; }; then
      local silent
      [[ -e "./${folderName}/.eslintrc.js" ]] && silent="true"
      file_copyToFolder "${PATH_ESLintConfigFile}" "./${folderName}" ${silent}
    fi
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

    deleteFile package-lock.json
    logInfo "Installing: ${folderName}"
    logInfo

    npm install
    throwError "Error installing module"

    npm audit
  }

  _link() {
    local lib=
    createFolder "${outputDir}"
#    copyFileToFolder package.json "${outputDir}"

#    logDebug "Setting version '${version}' to module: ${folderName}"
#    setVersionName "${version}" "${outputDir}/package.json"

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
    _cd src
    local folders=($(listFolders))
    _cd..

    for folder in "${folders[@]}"; do
      [[ "${folder}" == "test" ]] && continue

      local absoluteSourcesFolder="$(pwd)/src/${folder}"
      local absoluteOutputDir="$(pwd)/${outputDir}"

      logInfo "Compiling($(tsc -v)): ${folderName}/${folder}"
      tsc -p "./src/${folder}/tsconfig.json" --rootDir "./src/${folder}" --outDir "${outputDir}" ${compilerFlags[@]}
      throwWarning "Error compiling: ${module}/${folder}"

      _cd "${absoluteSourcesFolder}"
      find . -name '*.scss' | cpio -pdm "${absoluteOutputDir}" > /dev/null
      find . -name '*.svg' | cpio -pdm "${absoluteOutputDir}" > /dev/null
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