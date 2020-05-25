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

enforceBashVersion 4.4

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

  local _tsLibs=()
  local _projectLibs=()
  local _apps=()

  local _activeLibs=()
  local _allLibs=()

  createPackages() {
    local className="${1}"
    local version="${2}"
    local libs=(${@:3})
    local ref

    for lib in ${libs[@]}; do
      [[ ! -e "${lib}" ]] && continue
      [[ ! -e "${lib}/package.json" ]] && continue

      ref=$(string_replaceAll "-" "_" "${lib}")

      new "${className}" "${ref}"
      "${ref}".folderName = "${lib}"
      "${ref}".path = "$(pwd)"
      "${ref}".prepare
      "${ref}".outputDir = "${outputDir}"
      "${ref}".outputTestDir = "${outputTestDir}"
      "${ref}".version = "${version}"

      [[ "$(array_contains "${lib}" ${tsLibs[@]})" ]] && _tsLibs+=(${ref})
      [[ "$(array_contains "${lib}" ${projectLibs[@]})" ]] && _projectLibs+=(${ref})
      [[ "$(array_contains "${lib}" ${backendApps[@]} ${frontendApps[@]})" ]] && _apps+=(${ref})

      [[ "$(array_contains "${lib}" ${activeLibs[@]})" ]] && _activeLibs+=(${ref})
      _allLibs+=(${ref})
    done
  }

  [[ "${ThunderstormHome}" ]] && [[ "${ts_linkThunderstorm}" ]] && _pushd "${ThunderstormHome}"
  createPackages NodePackage "$(workspace.thunderstormVersion)" ${tsLibs[@]}
  [[ "${ThunderstormHome}" ]] && [[ "${ts_linkThunderstorm}" ]] && _popd

  createPackages NodePackage "$(workspace.appVersion)" ${projectLibs[@]}
  createPackages FrontendPackage "$(workspace.appVersion)" "${frontendApps[@]}"
  createPackages BackendPackage "$(workspace.appVersion)" "${backendApps[@]}"

  ((${#_activeLibs[@]} == 0)) && _activeLibs=(${_allLibs[@]})

  workspace.tsLibs = "${_tsLibs[@]}"
  workspace.projectLibs = "${_projectLibs[@]}"
  workspace.active = "${_activeLibs[@]}"
  workspace.apps = "${_apps[@]}"
  workspace.allLibs = "${_allLibs[@]}"

  #  workspace.toLog
  workspace.setEnvironment

  workspace.purge
  workspace.clean
  workspace.install
  workspace.link
  workspace.compile
  workspace.lint
  workspace.test

  workspace.publish
  workspace.launch
  workspace.deploy

}

buildWorkspace

#zevel() {
#  echo "${1}er"
#}
#
#original="what a piece rap of crap this little crap is"
#echo "${original}" | sed -E "s/(rap)/$(zevel \\1)/g"
