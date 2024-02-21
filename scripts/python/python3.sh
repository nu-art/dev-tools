#!/bin/bash

python3.install() {
    local version="${1:-"3.11"}"

    if [[ $(python3.isInstalled) -eq 0 ]]; then
        if ! [[ "$(python3.version)" =~ ${version} ]]; then
            if [[ $(isMacOS) == "true" ]]; then
                brew update
                bannerInfo "Python3 - Installing v${version}"
                brew install python@${version}
				python3 -m ensurepip --upgrade
            else
                # Assuming apt for non-macOS systems; adjust as necessary
                bannerInfo "Python3 - Installing v${version}"
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip
                python3 --version
                pip3 --version
                # Use update-alternatives to set python3 as the default python version if needed
            fi
        fi
    fi

    logInfo "Python3 - Installed ${version}"
}

python3.isInstalled() {
	[[ -x "$(command -v python3)" ]] && return 0
}

python3.version() {
	if [[ -x "$(command -v python3)" ]]; then
		python3 --version
	fi
}

python3.installvenv() {
	logInfo "PIP3 - Installing packages ${*}"
	if [[ $(isMacOS) == "true" ]]; then
	  	pip3 install venv
	else
	  sudo pt-get install python3-venv
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
