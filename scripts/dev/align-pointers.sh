#!/bin/bash
branchName=
updateSubmodules=
force=

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;

            "--gsu")
                updateSubmodules="true"
            ;;

            "--force")
                force="--force"
            ;;

            "*")
                echo "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}

function printUsage() {
    logVerbose
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${branchName}"
    logVerbose
    exit 0
}

function verifyRequirement() {
    missingData=
    if [[ ! "${branchName}" ]]; then
        branchName="--branch=${paramColor}branch-name${NoColor}"
        missingData=true
    fi

    if [[ "${missingData}" ]]; then
        printUsage
    fi
}

echo "Aligning all of the repositories to ${branchName}"
git pull && git checkout ${branchName} && git pull

bash ./dev-tools/scripts/git/git-checkout.sh --branch=${branchName} --project ${force}
bash ./dev-tools/scripts/git/git-pull.sh --project

if [[ "updateSubmodules" == "yes" ]]; then
	echo "calling git submodule update --init"
	git submodule update --init
fi

echo "Done aligning all of the repositories to ${branchName}"
