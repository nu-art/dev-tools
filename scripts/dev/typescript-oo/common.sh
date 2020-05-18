#!/bin/bash

copyConfigFile() {
  local filePattern=${1}
  local targetFile=${2}

  local envs=(${@:3})

  for env in ${envs[@]}; do
    local envConfigFile=${filePattern//ENV_TYPE/${env}}
    [[ ! -e "${envConfigFile}" ]] && continue

    logDebug "Setting ${targetFile} from env: ${env}"
    cp "${envConfigFile}" "${targetFile}"
    return 0
  done

  throwError "Could not find a match for target file: ${targetFile} in envs: ${envs[@]}" 2
}
