#!/bin/bash

source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/git-core.sh

paramColor=${BRed}
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
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --from=${fromBranch} --to=${toBranch}"
    echo -e "  "
    echo
    exit 0
}

function verifyRequirement() {
    missingData=false
    if [ "${fromBranch}" == "" ]; then
        fromBranch="${paramColor}Branch-to-be-merged-from${NoColor}"
        missingData=true
    fi

    if [ "${toBranch}" == "" ]; then
        toBranch="${paramColor}Branch-to-merge-onto${NoColor}"
        missingData=true
    fi

    if [ "${missingData}" == "true" ]; then
        printUsage
    fi

}

extractParams "$@"
verifyRequirement


banner "Main Repo"
if [ `gitGetCurrentBranch` != "${toBranch}" ]; then
    logError "Main Repo MUST be on branch: ${toBranch}"
    exit 1
fi

gitMerge ${fromBranch}

conflictingSubmodules=(`getAllConflictingSubmodules "${projectsToIgnore[@]}"`)
echo
echo "conflictingSubmodules: ${conflictingSubmodules[@]}"

for submoduleName in "${conflictingSubmodules[@]}"; do
    cd ${submoduleName}
        if [ `gitGetCurrentBranch` != "${toBranch}" ]; then
            logError "Submodule ${submoduleName} MUST be on branch: ${toBranch}"
            cd ..
            exit 1
        fi
    cd ..
done

for submoduleName in "${conflictingSubmodules[@]}"; do
    banner "${submoduleName}"
    cd ${submoduleName}
        gitMerge ${fromBranch}
    cd ..
done

changedSubmodules=(`getAllChangedSubmodules "${projectsToIgnore[@]}"`)
echo
echo "changedSubmodules: ${changedSubmodules[@]}"
gitUpdateSubmodules "${changedSubmodules[@]}"

#
#echo
#banner "Main Repo"
#gitCommit "${toBranch}"
#gitPush
