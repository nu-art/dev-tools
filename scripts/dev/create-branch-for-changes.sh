#!/bin/bash

projectsToIgnore=("dev-tools")

source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh
source ${BASH_SOURCE%/*}/../utils/git-tools-new.sh

branchName=${1}
commitMessage=${2}


paramColor=${BBlue}
valueColor=${BGreen}
function printUsage {
    echo
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor} --branch=${branchName} --message=\"${paramColor}Commit Message${NoColor}\""
    echo -e "  "
    echo
    exit 0
}

function extractParams() {
    echo
    logInfo "Process params: "
    for (( lastParam=1; lastParam<=$#; lastParam+=1 )); do
        paramValue="${!lastParam}"
        logDebug "  param: ${paramValue}"

        case "${paramValue}" in
            "--dry-run")
                setDryRun true
            ;;

            "--branch="*)
                branchName=`echo "${paramValue}" | sed -E "s/--branch=(.*)/\1/"`
            ;;

            "--message="*)
                commitMessage=`echo "${paramValue}" | sed -E "s/--message=(.*)/\1/"`
            ;;
        esac
    done

    echo
    logInfo "Running with params:"
    logDebug "  dryRun: ${dryRun}"
    logDebug "  branchName: ${branchName}"
    logDebug "  commitMessage: ${commitMessage}"
}

function verifyRequirement() {
    if [ "${branchName}" == "" ]; then
        branchName="<${paramColor}NewBranchName${NoColor}>"
        printUsage
    fi

    if [ "${commitMessage}" == "" ]; then
        printUsage
    fi
}

extractParams "$@"
verifyRequirement

#git checkout -b "$branchName"
hasUntracked=(`git status | grep -e "modified: .*untracked content" | sed -E "s/modified: (.*)\(.*/\1/"`)
hasModified=(`git status | grep -e "modified: .*modified content" | sed -E "s/modified: (.*)\(.*/\1/"`)
hasCommits=(`git status | grep -e "modified: .*new commits" | sed -E "s/modified: (.*)\(.*/\1/"`)


function ignoringRepo() {
    contains $1 "${projectsToIgnore[@]}"
}

function isUntracked() {
    contains $1 "${hasUntracked[@]}"
}

function isModified() {
    contains $1 "${hasModified[@]}"
}

function isCommitted() {
    contains $1 "${hasCommits[@]}"
}

ALL_REPOS=()
ALL_REPOS+=(${hasUntracked[@]})
ALL_REPOS+=(${hasModified[@]})
ALL_REPOS+=(${hasCommits[@]})

repos=()

for projectName in "${ALL_REPOS[@]}"; do
    if [ `ignoringRepo ${projectName}` == "true" ]; then
        continue
    fi

    if [ `contains ${projectName} ${repos[@]}` == "true" ]; then
        continue
    fi

    repos+=(${projectName})
done

if [ "${repos#}" == "0" ]; then
    exit 0
fi

banner "Main Repo"
gitCheckoutBranch ${branchName}

for projectName in "${repos[@]}"; do
    echo
    banner "${projectName}"
    cd ${projectName}
        pwd
        gitCheckoutBranch ${branchName}
        gitAddAll
        gitCommit "${commitMessage}"
        gitPush
    cd ..
done

echo
banner "Main Repo"
gitCommit "${commitMessage}"
gitPush
