#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/firebase/core.sh
source ./dev-tools/scripts/node/_source.sh
source ./dev-tools/scripts/oos/core/transpiler.sh

#setDebugLogFile ./.trash/debug-log.txt
CONST_RunningFolder="$(folder_getRunningPath 1)"
logInfo "${CONST_RunningFolder}"
setDebugLog true
setTranspilerOutput "${CONST_RunningFolder}"
addTranspilerClassPath "${CONST_RunningFolder}/classes"

setErrorOutputFile "$(pwd)/error_message.txt"

# shellcheck source=./common.sh
source "${BASH_SOURCE%/*}/common.sh"

# shellcheck source=./modules.sh
source "${BASH_SOURCE%/*}/modules.sh"

# shellcheck source=./params.sh
source "${BASH_SOURCE%/*}/params.sh"

[[ -e ".scripts/setup.sh" ]] && source .scripts/setup.sh
[[ -e ".scripts/signature.sh" ]] && source .scripts/signature.sh

[[ -e ".scripts/modules.sh" ]] && source .scripts/modules.sh

enforceBashVersion 4.4

#signature
extractParams "$@"
printDebugParams "${debug}" "${params[@]}"
setLogLevel ${tsLogLevel}
installAndUseNvmIfNeeded

buildWorkspace() {
  local thunderstormLibraries=(
    ts-common
    testelot
    #    neural
    #    firebase
    #    thunderstorm
    #    db-api-generator
    #    storm
    #    live-docs
    #    user-account
    #    permissions
    #    push-pub-sub
    #    bug-report
  )

  local projectLibraries=(
    app-shared
  )

  new Workspace workspace
  workspace.prepare

  local libraries=()

  createPackages() {
    local className="${1}"
    local version="${2}"
    local libs=(${@:3})
    local ref

    for lib in ${libs[@]}; do
      ref=$(string_replaceAll "-" "_" "${lib}")

      new "${className}" "${ref}"
      "${ref}".folderName = "${lib}"
      "${ref}".prepare
      "${ref}".outputDir = "${outputDir}"
      "${ref}".outputTestDir = "${outputTestDir}"
      "${ref}".version = "${version}"
      libraries+=(${ref})
    done
  }

  createPackages NodePackage "$(workspace.thunderstormVersion)" ${thunderstormLibraries[@]}
  createPackages NodePackage "$(workspace.appVersion)" ${projectLibraries[@]}
  createPackages FrontendPackage "$(workspace.appVersion)" ${frontendModule}
  createPackages BackendPackage "$(workspace.appVersion)" ${backendModule}

  workspace.libraries = "${libraries[@]}"

  #  workspace.purge
  workspace.clean
  #  workspace.install
  #  workspace.link
  #  workspace.compile
  #  workspace.lint
  #  workspace.test

  workspace.toLog
}

buildWorkspace

#zevel() {
#  echo "${1}er"
#}
#
#original="what a piece rap of crap this little crap is"
#echo "${original}" | sed -E "s/(rap)/$(zevel \\1)/g"