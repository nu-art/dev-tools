#!/bin/bash

printAndIterateLineByLine() {
  local input="${1}"
  local processor="${2}"
  local tempFile=temp.txt
  echo "${input}" > "${tempFile}"

  while IFS='' read -r line || [[ -n "$line" ]]; do
    ${processor} "${line}"
  done < "${tempFile}"

  rm "${tempFile}"
}

printHelp() {
  signatureThunderstorm

  local COLOR_PARAM="${BBlue}"
  local COLOR_GROUP="${BCyan}"
  local COLOR_OPTION="${Purple}"
  local COLOR_OPTION_DEFAULT="${BPurple}"
  local COLOR_WARNING="${Yellow}"
  local COLOR_WARNING_BOLD="${BYellow}"
  local COLOR_DESCRIPTION_DEFAULT="${BGreen}"
  local COLOR_DESCRIPTION="${Green}"
  local COLOR_NONE="${COLOR_NONE}"

  local warnings=()
  local documents=()
  local params=
  local defaultOption=
  local options=

  processLine() {
    local line="${1}"
    case "${line}" in
    *#*"===="*)
      local title=$(echo "${line}" | sed -E "s/.*==== (.*) ====/\1/")
      [[ ! "${title}" ]] && throwError "Bad line format for title: \"${line}\"" 2
      logVerbose
      bannerVerbose "${title}:" ${COLOR_GROUP}
      ;;

    *#*"DOC:"*)
      local _document="$(echo "${line}" | sed -E "s/.*DOC: (.*)$/\1/")"
      [[ ! "${_document}" ]] && throwError "Bad line format for documentation: \"${line}\"" 2
      documents+=("${_document}")
      ;;

    *#*"WARNING:"*)
      local _warning="$(echo "${line}" | sed -E "s/.*WARNING: (.*)$/\1/")"
      [[ ! "${_warning}" ]] && throwError "Bad line format for warning: \"${line}\"" 2
      warnings+=("${_warning}")
      ;;

    *#*"DEFAULT_PARAM="*)
      defaultOption=$(echo "${line}" | sed -E "s/.*DEFAULT_PARAM=(.*)$/\1/")
      ;;

    *#*"PARAM="*)
      local __options=$(echo "${line}" | sed -E "s/.*PARAM=(.*)$/\1/")
      [[ ! "${__options}" ]] && throwError "Bad line format for param: \"${line}\"" 2
      local _options="$(echo "${__options}" | sed -E "s/.*\[(.*)\].*/\1/")"
      options=(${_options// | / })
      ;;

    *"   \""*"\""*")"*)
      #  "--launch-frontend" | "-lf")
      local tempParams="$(echo "${line}" | sed -E 's/.*   "([a-z-]*=?)"\*? \| "([a-z-]*=?)"\*?\).*/\1 \2/')"

      [[ "${line}" == "${tempParams}" ]] && tempParams="$(echo "${line}" | sed -E 's/.*   "([a-z-]*=?)"\*?\)$/\1/')"
      [[ "${line}" == "${tempParams}" ]] && throwError "Bad line format for parameters: '${line}'" 2

      params=(${tempParams})
      ;;

    *)
      [[ ! ${params} ]] && return

      for ((i = 0; i < ${#options[@]}; i++)); do
        [[ "${options[${i}]}" != "${defaultOption}" ]] && continue
        options[${i}]="${COLOR_OPTION_DEFAULT}${options[${i}]}"
      done

      local optionsAsString=$(string_join " ${COLOR_SEPARATOR}|${COLOR_OPTION} " "${options[@]}")
      for ((i = 0; i < ${#params[@]}; i++)); do
        [[ ! $(string_endsWith "${params[${i}]}" "=") ]] && continue
        params[${i}]="${params[${i}]}\"${COLOR_OPTION}${optionsAsString}${COLOR_PARAM}\""
      done

      logVerbose "   ${COLOR_PARAM}$(string_join " ${COLOR_SEPARATOR}|${COLOR_PARAM} " "${params[@]}")${COLOR_NONE}"
      for warning in "${warnings[@]}"; do
        logVerbose "        ${COLOR_WARNING_BOLD}WARNING: ${COLOR_WARNING}${warning}${COLOR_NONE}"
      done

      for document in "${documents[@]}"; do
        logVerbose "        ${COLOR_DESCRIPTION}${document}${COLOR_NONE}"
      done

      [[ "${defaultOption}" ]] && logVerbose "        ${COLOR_DESCRIPTION_DEFAULT}DEFAULT: ${COLOR_DESCRIPTION}${defaultOption}${COLOR_NONE}"

      params=
      documents=()
      warnings=()
      options=
      defaultOption=
      logVerbose

      ;;
    esac
  }

  local paramsFile="${1}"
  [[ ! -e "${paramsFile}" ]] && throwError "File doesn't exists: ${paramsFile}" 2

  local output="$(cat "${paramsFile}")"
  printAndIterateLineByLine "${output}" processLine
  exit 0
}
