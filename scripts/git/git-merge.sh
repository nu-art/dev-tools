#!/bin/bash

source ${BASH_SOURCE%/*}/_core.sh

runningDir=${PWD##*/}
projectsToIgnore=("dev-tools")
params=(fromBranch toBranch)

function extractParams() {
    logVerbose
    logInfo "Process params: "
    for paramValue in "${@}"; do
        logDebug "  param: ${paramValue}"
        case "${paramValue}" in
            "--from="*)
                fromBranch=`echo "${paramValue}" | sed -E "s/--from=(.*)/\1/"`
            ;;

            "--to="*)
                toBranch=`echo "${paramValue}" | sed -E "s/--to=(.*)/\1/"`
            ;;

            "--debug")
                debug="true"
            ;;
        esac
    done
}

function printUsage() {
    logVerbose
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromBranch} ${toBranch}"
    logVerbose
    exit 0
}

function verifyRequirement() {
    local missingParamColor=${BRed}
    local existingParamColor=${BBlue}

    missingData=false
    if [ "${fromBranch}" == "" ]; then
        fromBranch="${missingParamColor}Branch-to-be-merged-from"
        missingData=true
    fi

    if [ "${toBranch}" == "" ]; then
        toBranch="${missingParamColor}Branch-to-merge-onto"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        fromBranch=" --from=${existingParamColor}${fromBranch}${NoColor}"
        toBranch=" --to=${existingParamColor}${toBranch}${NoColor}"

        printUsage
    fi
}

extractParams "$@"
verifyRequirement

signature
printDebugParams ${debug} "${params[@]}"


function execute() {
    currentBranch=`gitGetCurrentBranch`
    if [  "${currentBranch}" != "${toBranch}" ]; then
        logError "MUST be on branch: ${toBranch} but found: ${currentBranch}"
        return
    fi

    gitMerge ${fromBranch}
}

function processSubmodule() {
    local mainModule=${1}
    bannerDebug "${mainModule}"

    execute

    local submodules=(`getSubmodulesByScope "conflict" "${projectsToIgnore[@]}"`)
#    echo
#    echo "conflictingSubmodules: ${submodules[@]}"

    for submodule in "${submodules[@]}"; do
        cd ${submodule}
            processSubmodule "${mainModule}/${submodule}"
        cd ..
    done

    local submodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
#    echo
#    echo "changedSubmodules: ${submodules[@]}"
    gitUpdateSubmodules "${submodules[@]}"
}


processSubmodule "${runningDir}"