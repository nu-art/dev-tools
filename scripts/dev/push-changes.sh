#!/bin/bash


source ${BASH_SOURCE%/*}/tools.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh

runningDir=${PWD##*/}
projectsToIgnore=("dev-tools")
params=(branchName commitMessage)

function extractParams() {
    echo
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;

            "--message="*)
                commitMessage=`echo "${paramValue}" | sed -E "s/--message=(.*)/\1/"`
            ;;

            "--debug")
                debug="true"
            ;;
        esac
    done
}

function printUsage() {
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${branchName} ${commitMessage}"
    echo -e "  "
    echo
    exit 0
}

function verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    local missingData=false
    if [ "${branchName}" == "" ]; then
        branchName="${missingParamColor}new-branch-name"
        missingData=true
    fi

    if [ "${commitMessage}" == "" ]; then
        commitMessage="${missingParamColor}Commit message here"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        branchName="--branch=${existingParamColor}${branchName}${NoColor}"
        commitMessage="--message=\"${existingParamColor}${commitMessage}${NoColor}\""
        printUsage
    fi
}


extractParams "$@"
verifyRequirement

signature
printDebugParams ${debug} "${params[@]}"

function processSubmodule() {
    local mainModule=${1}
    echo
    bannerDebug "${mainModule}"
    gitCheckoutBranch ${branchName} true

    local submodules=(`getSubmodulesByScope "changed" "${projectsToIgnore[@]}"`)

#    echo
#    bannerWarning "changedSubmodules: ${submodules}"

    if [ "${#submodules[@]}" -gt "0" ]; then
        for submoduleName in "${submodules[@]}"; do
            cd ${submoduleName}
                processSubmodule "${mainModule}/${submoduleName}"
            cd ..
        done
        echo
        bannerDebug "${mainModule} - continue"
    fi

    gitAddAll
    gitCommit "${commitMessage}"
    gitPush ${branchName}
}

processSubmodule "${runningDir}"