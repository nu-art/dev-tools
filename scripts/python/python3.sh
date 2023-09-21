#!/bin/bash

python3.install() {
	local version="${1:-"3.11"}"

	if [[ $(python3.isInstalled) -eq 0 ]]; then
		[[ "$(python3.version)" =~ ${version} ]] && return 0
	fi

  if [[ $(isMacOS) ]]; then
    brew update
    bannerInfo "Python3 - Installing v${version}"
    brew install python@${version}
    python3 -m ensurepip --upgrade
    logInfo "Python3 - Installed ${version}"
  else
    apt update
    apt upgrade
    bannerInfo "Python3 - Installing v${version}"
    apt install python${version}
    apt install python${version}-venv
    python3 -m ensurepip --upgrade
    logInfo "Python3 - Installed ${version}"
  fi
}

python3.isInstalled() {
	[[ -x "$(command -v python3)" ]] && return 0
}

python3.version() {
	if [[ -x "$(command -v python3)" ]]; then
		python3 --version
	fi
}

python3.setVenv() {
	local envName=${1}
	logInfo "Setting up VENV - ${envName}"
	python3 -m venv "${envName}"
	source "${envName}/bin/activate"

}

python3.installRequirements() {
	local folderName=${1:-.}
	logInfo "PIP3 - Installing Requirements"
	pip3 install -r "${folderName}/requirements.txt"
}

python3.uninstallRequirements() {
	local folderName=${1:-.}
	logInfo "PIP3 - Uninstalling Requirements"
	pip3 uninstall -r "${folderName}/requirements.txt"
}

python3.installPackages() {
	logInfo "PIP3 - Installing packages ${*}"
	pip3 install "${@}"
}

python3.uninstallPackages() {
	logInfo "PIP3 - Uninstalling packages ${*}"
	python3 uninstall "${@}"
}

python3.run() {
	local pathToMainFile=${1}
	export PYTHONPATH=.
	python3 "${pathToMainFile}" ${@:2}
}
