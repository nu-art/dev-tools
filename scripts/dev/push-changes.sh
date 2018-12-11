#!/bin/bash


source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh

paramColor=${BRed}
projectsToIgnore=("dev-tools")

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

function printDebugParams() {
    if [ ! "${debug}" ]; then
        return
    fi

    function printParam() {
        if [ ! "${2}" ]; then
            return
        fi

        logDebug "--  ${1}: ${2}"
    }

    logInfo "------- DEBUG: PARAMS -------"
    logDebug "--"
    printParam "branchName" ${branchName}
    printParam "commitMessage" ${commitMessage}
    printParam "debug" ${debug}
    logDebug "--"
    logInfo "----------- DEBUG -----------"
    echo
}

extractParams "$@"
verifyRequirement

# Commented out because I had changes and I didn't create branch.. and cuz it is now recursive.. this enforcement makes no sense
#
#currentBranch=`gitGetCurrentBranch`
#if [ "${currentBranch}" != "${branchName}" ]; then
#    logError "Main Repo MUST be on branch: ${branchName}"
#    exit 1
#fi

signature
printDebugParams

function pushChanges() {
    local mainRepo=${1}
    bannerDebug "${mainRepo}"
    gitCheckoutBranch ${branchName} true

    local changedSubmodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
    if [ "${#changedSubmodules[@]}" -gt "0" ]; then
        logInfo "pushing changes to submodules of: ${mainRepo}"
        for submoduleName in "${changedSubmodules[@]}"; do
            echo
            cd ${submoduleName}
                pushChanges ${submoduleName}
            cd ..
        done
        bannerDebug "${mainRepo}"
    fi

    gitAddAll
    gitCommit "${commitMessage}"
    gitPush ${branchName}
}

pushChanges "Main Repo"