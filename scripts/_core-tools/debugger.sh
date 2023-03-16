#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash
CONST_DEBUGGER_COMMANDS_HISTORY="$(pwd)/.trash/debugger"
CONST_DEBUGGER_ENABLED=
CONST_escape_char=$(printf "\u1b")

#local sourceFiles=()
#for ((arg = 2; arg < ${#FUNCNAME[1]}; arg += 1)); do
#  sourceFiles+=("$(fixSource "${BASH_SOURCE[1]}")")
#done
enableDebugger() {
  CONST_DEBUGGER_ENABLED=true
}

disableDebugger() {
  CONST_DEBUGGER_ENABLED=
}

breakpoint() {
  [[ ! "${CONST_DEBUGGER_ENABLED}" ]] && return

  breakpointImpl() {
    # shellcheck disable=SC2034
    local var="CONST_DEBUGGER_VAR"
    local label="${1}"
    local wipCommand=""

    local historyCommands=()
    [[ -e "${CONST_DEBUGGER_COMMANDS_HISTORY}" ]] && readarray -t historyCommands < "${CONST_DEBUGGER_COMMANDS_HISTORY}"
    local historyIndex=$((${#historyCommands[@]} - 1))

    if [[ "${label}" ]]; then
      logInfo "Breakpoint: ${label}"
      logInfo "${Cyan} ${BASH_SOURCE[2]} ${Purple} ${FUNCNAME[2]}() ${Gray} [${BASH_LINENO[2]}]${NoColor}"
    fi

    local input=
    [[ ! "${input}" ]] && ((historyIndex >= 0)) && input="${historyCommands[${historyIndex}]}"
    [[ ! "${input}" ]] && input=""

    local _input=${input}
    local pos=${#_input}

    while true; do
      local start="$(string.substring "${input}" 0 ${pos})"
      local mid="$(string.substring "${input}" ${pos} 1)"
      local end="$(string.substring "${input}" $((pos + 1)))"
      [[ "${mid}" == "" ]] && mid=" "

      _input="${start}${On_Cyan}${mid}${NoColor}${end}"
      echo -e "${_input}"
      read -rsN1 mode # get 1 character
      #      printf %d\\n \'$mode
      if [[ $mode == "${CONST_escape_char}" ]]; then
        read -rsn2 mode # read 2 more chars
        #        printf "mode: %s" ${mode}
      fi

      case "$mode" in
      '[A')
        deleteTerminalLine
        ((historyIndex == 0)) && continue
        historyIndex=$((historyIndex - 1))
        input="${historyCommands[${historyIndex}]}"
        pos=${#input}
        ;;

      '[B')
        deleteTerminalLine
        ((historyIndex == ${#historyCommands[@]})) && input="${wipCommand}" && continue
        historyIndex=$((historyIndex + 1))
        input="${historyCommands[${historyIndex}]}"
        pos=${#input}
        ;;

      '[3')
        read -rsn1 mode # get 1 character
        deleteTerminalLine
        ((pos == 0)) && continue
        start="$(string.substring "${input}" 0 $((pos)))"
        end="$(string.substring "${input}" $((pos + 1)))"
        input="${start}${end}"
        ;;

      '[C')
        deleteTerminalLine
        ((pos == ${#input})) && continue
        pos=$((pos + 1))
        ;;

      '[D')
        deleteTerminalLine
        ((pos == 0)) && continue
        pos=$((pos - 1))
        ;;

      $'\177')
        ((pos == 0)) && continue
        start="$(string.substring "${input}" 0 $((pos - 1)))"
        end="$(string.substring "${input}" $((pos)))"
        input="${start}${end}"

        pos=$((pos - 1))
        deleteTerminalLine
        ;;

      *)
        if [[ "${mode}" != " " ]] && (($(printf %d\\n \'$mode) == 0)); then
          [[ "${input}" == "continue" ]] || [[ "${input}" == ":c" ]] && return
          [[ ! "${input}" ]] && deleteTerminalLine && continue
          #        echo eval "${input}"
          deleteTerminalLine

          echo -e "Evaluating: '${BBlack}${input}${NoColor}'"
          dontExit true
          eval "${input}"
          local exitCode=$?
          dontExit

          if ((exitCode < 2)); then
            array_remove historyCommands "${input}"
            historyCommands+=("${input}")

            printf "%s\n" "${historyCommands[@]}" > "${CONST_DEBUGGER_COMMANDS_HISTORY}"
          fi
          echo
        else
          start="$(string.substring "${input}" 0 ${pos})"
          end="$(string.substring "${input}" $((pos)))"
          input="${start}${mode}${end}"
          wipCommand="${input}"
          pos=$((pos + 1))
          deleteTerminalLine
        fi
        ;;
      esac
      #        echo
    done
  }

  trap 'echo "Releasing breakpoint" && return' SIGINT
  breakpointImpl "${@}"
  trap - SIGINT
}
