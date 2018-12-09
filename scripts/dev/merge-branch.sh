#!/bin/bash

source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/git-core.sh
source ${BASH_SOURCE%/*}/../_fun/signature.sh


projectsToIgnore=("dev-tools")

function extractParams() {
    echo
    logInfo "Process params: "
    for paramValue in "${@}"; do
        logDebug "  param: ${paramValue}"
        case "${paramValue}" in
            "--dry-run")
                setDryRun true
            ;;

            "--from="*)
                fromBranch=`echo "${paramValue}" | sed -E "s/--from=(.*)/\1/"`
            ;;

            "--to="*)
                toBranch=`echo "${paramValue}" | sed -E "s/--to=(.*)/\1/"`
            ;;
        esac
    done

    echo
    logInfo "Running with params:"
    logDebug "  fromBranch: ${fromBranch}"
    logDebug "  toBranch: ${toBranch}"
}

function printUsage() {
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} ${fromBranch} ${toBranch}"
    echo -e "  "
    echo
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
        fromBranchParam=" --from=${existingParamColor}${fromBranch}${NoColor}"
        toBranchParam=" --to=${existingParamColor}${toBranch}${NoColor}"

        printUsage
    fi
}

extractParams "$@"
verifyRequirement

signature
bannerDebug "Main Repo"
currentBranch=`gitGetCurrentBranch`
if [  "${currentBranch}" != "${toBranch}" ]; then
    logError "Main Repo MUST be on branch: ${toBranch}"
    exit 1
fi

gitMerge ${fromBranch}

conflictingSubmodules=(`getAllConflictingSubmodules "${projectsToIgnore[@]}"`)
echo
echo "conflictingSubmodules: ${conflictingSubmodules[@]}"

for submoduleName in "${conflictingSubmodules[@]}"; do
    cd ${submoduleName}
        currentBranch=`gitGetCurrentBranch`
        if [ "${currentBranch}" != "${toBranch}" ]; then
            logError "Submodule ${submoduleName} MUST be on branch: ${toBranch}"
            cd ..
            exit 1
        fi
    cd ..
done

for submoduleName in "${conflictingSubmodules[@]}"; do
    bannerDebug "${submoduleName}"
    cd ${submoduleName}
        gitMerge ${fromBranch}
    cd ..
done

changedSubmodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
echo
echo "changedSubmodules: ${changedSubmodules[@]}"
gitUpdateSubmodules "${changedSubmodules[@]}"