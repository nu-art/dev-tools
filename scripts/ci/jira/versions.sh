#!/bin/bash

function jiraCreateNewVersion() {
    local projectId=${1}
    local version=${2}
    local description=${3}
    local released=${4}
    local archived=${5}

   curl --request POST \
        --url "https://introb.atlassian.net/rest/api/3/version" \
        --user "${JIRA_USER}:${JIRA_TOKEN}"
        --data "{\"\":}"
}

curl --request DELETE \
  --url '/rest/api/3/version/{id}' \
  --user 'email@example.com:<api_token>'
