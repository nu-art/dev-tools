#!/bin/bash
source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/firebase/core.sh
source ./dev-tools/scripts/node/_source.sh
source ./dev-tools/scripts/oos/core/transpiler.sh

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

#signature
extractParams "$@"

CONST_RunningFolder="$(folder_getRunningPath 1)"
#setTranspilerOutput "${CONST_RunningFolder}"
setTranspilerOutput ".trash/bai"
addTranspilerClassPath "${CONST_RunningFolder}/classes"

buildWorkspace() {

  installAndUseNvmIfNeeded
  storeFirebasePath

  new Workspace workspace
  workspace.appVersion = "${appVersion}"
  workspace.prepare

  [[ -e "${CONST_BuildWatchFile}" ]] && readarray -t activeWatches < "${CONST_BuildWatchFile}"

  local _tsLibs=()
  local _projectLibs=()
  local _apps=()

  local _ts_runTests=()
  local _allLibs=()

  createPackages() {
    local className="${1}"
    local version="${2}"
    local libs=(${@:3})
    local ref

    for lib in "${libs[@]}"; do
      [[ ! -e "${lib}" ]] && continue
      [[ ! -e "${lib}/package.json" ]] && continue

      _logWarning "processing ${lib}"
      local watchProcessIds=()
      for watchLine in "${activeWatches[@]}"; do
        [[ ! "${watchLine}" ]] && continue
        [[ ! "${watchLine}" =~ ^${lib} ]] && continue

        watchProcessIds+=("${watchLine}")
      done
      ref=$(string_replaceAll "-" "_" "${lib}")

      _logWarning "new ${className} ${ref}"
      new "${className}" "${ref}"
      "${ref}".folderName = "${lib}"
      "${ref}".path = "$(pwd)"
      "${ref}".prepare
      "${ref}".outputDir = "${outputDir}"
      "${ref}".outputTestDir = "${outputTestDir}"
      "${ref}".version = "${version}"
      "${ref}".watchIds = "${watchProcessIds[@]}"

      [[ "$(array_contains "${lib}" "${tsLibs[@]}")" ]] && _tsLibs+=(${ref})
      [[ "$(array_contains "${lib}" "${projectLibs[@]}")" ]] && _projectLibs+=(${ref})
      [[ "$(array_contains "${lib}" "${executableApps[@]}" "${backendApps[@]}" "${frontendApps[@]}")" ]] && _apps+=(${ref})

      [[ "$(array_contains "${lib}" "${ts_activeLibs[@]}")" ]] && _activeLibs+=(${ref})
      _allLibs+=(${ref})
    done
  }

  [[ "${ThunderstormHome}" ]] && [[ "${ts_linkThunderstorm}" ]] && _pushd "${ThunderstormHome}"
  createPackages NodePackage "$(workspace.thunderstormVersion)" "${tsLibs[@]}"
  [[ "${ThunderstormHome}" ]] && [[ "${ts_linkThunderstorm}" ]] && _popd

  createPackages NodePackage "$(workspace.appVersion)" "${projectLibs[@]}"
  createPackages ExecutablePackage "$(workspace.appVersion)" "${executableApps[@]}"
  createPackages FrontendPackage "$(workspace.appVersion)" "${frontendApps[@]}"
  createPackages BackendPackage "$(workspace.appVersion)" "${backendApps[@]}"

  ((${#_activeLibs[@]} == 0)) && _activeLibs=(${_allLibs[@]})

  workspace.tsLibs = "${_tsLibs[@]}"
  workspace.projectLibs = "${_projectLibs[@]}"
  workspace.active = "${_activeLibs[@]}"
  workspace.apps = "${_apps[@]}"
  workspace.allLibs = "${_allLibs[@]}"

  #  breakpoint "before running workspace"

  #  workspace.toLog
  workspace.setEnvironment

  workspace.purge
  workspace.clean
  workspace.install
  workspace.link
  workspace.generate
  workspace.compile
  workspace.lint
  workspace.test

  workspace.copySecrets
  workspace.publish
  workspace.launch
  workspace.deploy

}

buildWorkspace
