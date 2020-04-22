#!/bin/bash

verifyFirebaseProjectIsAccessible() {
  local firebaseProject=${1}

  logDebug "Verifying You are logged in to firebase tools...'"
  [[ "${USER,,}" != "jenkins" ]] && firebase login
  logDebug

  logDebug "Verifying access to firebase project: '${firebaseProject}'"
  local output=$(firebase projects:list | grep "${firebaseProject}" 2>&1)
  if [[ "${output}" =~ "Command requires authentication" ]]; then
    logError "    User not logged in"
    return 2
  fi

  # shellcheck disable=SC2076
  if [[ ! "${output}" =~ "${firebaseProject}" ]]; then
    logError "    No access found"
    return 1
  fi
  return 0
}
