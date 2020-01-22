#!/bin/bash

JiraIssue() {

    declare __id=
    declare type=

    _updateFixVersion() {
        [[ ! "${__id}" ]] && throwError "Cannot update an issue without an id" 2
        local data=' {"fields":{"fixVersions":[{"id":"'${1}'"}]}}'

        _logDebug "Updating an issue without an id: ${__id}\n data: ${data}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request PUT \
             --url https://introb.atlassian.net/rest/api/3/issue/${__id} \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Content-Type: application/json' \
             --header 'Accept: application/json' \
             --data "${data}")

#        _logWarning "output: ${output}"
        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error updating an issue.\n\n${output}\n" "${responseCode}"

        return 0
    }

    _resolveType() {
        [[ ! "${__id}" ]] && throwError "Cannot get an issue without an id" 2

        _logDebug "Getting issue data without an id: ${__id}\n data: ${data}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request GET \
             --url https://introb.atlassian.net/rest/api/3/issue/${__id} \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Accept: application/json')

#        _logWarning "output: ${output}"
        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error getting issue.\n\n${output}\n" "${responseCode}"

        type=`echo "${output}" | grep -E "issuetype" | sed -E 's/^.*"issuetype".*"name":"(Story|Task|Sub-task|Bug)".*$/\1/'`

        return 0
    }

    _updateTransition() {
        [[ ! "${__id}" ]] && throwError "Cannot update an issue without an id" 2
        local data='{"transition":{"id":"'${1}'"}}'

        _logDebug "Updating an issue without an id: ${__id}\n data: ${data}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request POST \
             --url https://introb.atlassian.net/rest/api/3/issue/${__id}/transitions \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Content-Type: application/json' \
             --header 'Accept: application/json'\
             --data "${data}")

        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error getting issue.\n\n${output}\n" "${responseCode}"

        _logWarning "output: ${output}"
        return 0
    }

    _updateAssignee() {
        local data=`jsonSerialize ${__this} "accountId"`;
        local data='{"accountId":"'${1}'"}'

        _logDebug "Updating an issue without an id: ${__id}\n data: ${data}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request PUT \
             --url https://introb.atlassian.net/rest/api/3/issue/${__id}/assignee \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Content-Type: application/json' \
             --header 'Accept: application/json'\
             --data "${data}")

        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error getting issue.\n\n${output}\n" "${responseCode}"

#        _logWarning "output: ${output}"
        return 0
    }
}

