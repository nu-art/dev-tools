#!/bin/bash
storeFirebasePath() {
  CONST_Firebase=$(resolveCommand firebase)
  logError "${CONST_Firebase}"
}

verifyFirebaseProjectIsAccessible() {
  local firebaseProject=${1}

  logDebug "Verifying You are logged in to firebase tools...'"
  [[ "${USER,,}" != "jenkins" ]] && ${CONST_Firebase} login
  logDebug

  logDebug "Verifying access to firebase project: '${firebaseProject}'"
  local output=$(${CONST_Firebase} projects:list | grep "${firebaseProject}" 2>&1)
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
