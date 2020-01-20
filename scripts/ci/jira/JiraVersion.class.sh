#!/bin/bash

JiraVersion() {
    declare archived=false
    declare released=false
    declare id=
    declare name=
    declare releaseDate=
    declare description=
    declare projectId=

    _create() {
        [[ ! "${name}" ]] && throwError "Cannot create a version without a name" 2
        [[ ! "${projectId}" ]] && throwError "Cannot create a version without a projectId" 2

        _logDebug "Creating a version '${name}' for project with id: ${projectId}"
        local data=`jsonSerialize ${__this}`;

        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request POST \
             --url https://introb.atlassian.net/rest/api/3/version \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Content-Type: application/json' \
             --header 'Accept: application/json' \
             --data "${data}")

#         _logWarning "output: ${output}"
        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error creating version: ${name}.\n\n  ${output}\n" "${responseCode}"
        id=`echo "${output}" | grep -E "\"id\":" | sed -E "s/^.*\"id\":\"([a-zA-Z0-9\.]+)\".*$/\1/"`
    }

    _exists() {
        [[ ! "${name}" ]] && throwError "Cannot check for a version without a name" 2

        _logDebug "Checking if version exists for name: ${name}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request GET \
             --url https://introb.atlassian.net/rest/api/3/project/${projectId}/versions \
             --user ${JIRA_USER}:${JIRA_TOKEN} \
             --header 'Content-Type: application/json' \
             --header 'Accept: application/json')

#        _logWarning "output: ${output}"
        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error getting versions.\n\n${output}\n" "${responseCode}"
        id=`echo "${output}" | grep -E "${name}" | sed -E "s/.*\"id\":\"([a-zA-Z0-9\.]+)\".*,?\"name\":\"${name}\".*/\1/"`
    }

    _delete() {
        [[ ! "${id}" ]] && throwError "Cannot delete a version without an id" 2

        _logDebug "Deleting version with id: ${id}"
        local output=$(curl --write-out "\n--- Response: %{http_code} ---" \
             --request DELETE \
             --url https://introb.atlassian.net/rest/api/3/version/${id} \
             --user ${JIRA_USER}:${JIRA_TOKEN})

        local responseCode=`echo -e "${output}" | grep -E "Response:" | sed -E "s/--- Response: ([0-9]+) ---/\1/"`
        (( responseCode >= 400)) && throwError "Error getting versions.\n\n${output}\n" "${responseCode}"
    }
}

