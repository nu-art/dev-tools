#!/bin/bash
source ./dev-tools/scripts/oos/core/transpiler.sh

setErrorOutputFile "$(pwd)/error_message.txt"

# shellcheck source=./params.sh
source "${BASH_SOURCE%/*}/params.sh"

[[ -e ".scripts/signature.sh" ]] && source .scripts/signature.sh

#signature
extractParams "$@"

CONST_RunningFolder="$(folder.getRunningPath 1)"
#setTranspilerOutput "${CONST_RunningFolder}"
setTranspilerOutput ".trash/bai"
addTranspilerClassPath "${CONST_RunningFolder}/classes"

buildWorkspace() {

  new Workspace workspace
  workspace.setup
  workspace.loadApps
  # Workspace:
  #   load version from version file
  #   load list of apps
  #   set list of active apps
  #
  # Set Projects:
  #   future settings.gradle config
  #
  # detect connected devices
  #
  # Run lifecycle
  #
  workspace.setEnvironment

  workspace.purge
  workspace.clean
  workspace.install
  workspace.link
  workspace.generate
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
