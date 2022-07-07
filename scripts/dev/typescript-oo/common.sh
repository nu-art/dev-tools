#!/bin/bash

CONST_FrontendIconsPath="src/main/res/icons"
CONST_FrontendIconsFile="icons.tsx"
CONST_FrontendFontsPath="src/main/res/fonts"
CONST_FrontendFontsFile="fonts.tsx"
CONST_FrontendColorsPath="src/main/res"
CONST_FrontendColorsFile="colors.ts"

copyConfigFile() {
  local filePattern=${1}
  local targetFile=${2}
  local fail=${3}

  local envs=(${@:4})

  for env in ${envs[@]}; do
    local envConfigFile=${filePattern//ENV_TYPE/${env}}
    [[ ! -e "${envConfigFile}" ]] && continue

    logDebug "Setting ${targetFile} from env: ${env}"
    cp "${envConfigFile}" "${targetFile}"
    return 0
  done

  if((!fail)); then
    return 0
  fi

  throwError "Could not find a match for target file: ${targetFile} in envs: ${envs[@]}" 2
}
