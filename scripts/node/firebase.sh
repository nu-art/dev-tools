#!/bin/bash

firebase.setPath() {

  CONST_Firebase=$(which firebase)
  logWarning "Found firebase at: ${CONST_Firebase}"
}

firebase.verifyAccessToProject() {
  local firebaseProject=${1}

  logWarning "CONST_Firebase=${CONST_Firebase}"
  logDebug "Verifying You are logged in to firebase tools... command '${CONST_Firebase} login'"
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
    logError "    No access found to ${firebaseProject}"
    return 1
  fi
  return 0
}

firebase.login() {
  ${CONST_Firebase} login
}

firebase.use() {
  local firebaseProject=${1}
  $(resolveCommand firebase) use "${firebaseProject}"
}

firebase.deploy() {
  ${CONST_Firebase} deploy
  throwWarning "Error while deploying"
}

firebase.deploy.hosting() {
  ${CONST_Firebase} deploy --only hosting
  throwWarning "Error while deploying hosting"
}

firebase.deploy.functions() {
  ${CONST_Firebase} --debug deploy --only functions
  throwWarning "Error while deploying functions"
}
