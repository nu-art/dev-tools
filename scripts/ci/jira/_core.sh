#!/bin/bash
JIRA_USER=
JIRA_TOKEN=

[[ `type -t addTranspilerClassPath` != 'function' ]] && throwError "Must source './dev-tools/scripts/oos/core/transpiler.sh' in order to use this api" 4
addTranspilerClassPath ${BASH_SOURCE%/*}

setJiraAuth() {
    JIRA_USER=${1}
    JIRA_TOKEN=${2}
}
