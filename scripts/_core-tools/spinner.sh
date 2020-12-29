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
DEFAULT_SpinnerFrames=("—" "\\" "|" "/")

# Credit for the lovely spinner sequences
# https://unix.stackexchange.com/a/565551/248440

Spinner_Dot=("⠁" "⠂" "⠄" "⡀" "⢀" "⠠" "⠐" "⠈")
Spinner_Vertical=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂" "▁")
Spinner_Horizontal=("▉" "▊" "▋" "▌" "▍" "▎" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
Spinner_Arrows=("←" "↖" "↑" "↗" "→" "↘" "↓" "↙")
Spinner_WHAT=("▖" "▘" "▝" "▗")
Spinner_WHAT2=("┤" "┘" "┴" "└" "├" "┌" "┬" "┐")
Spinner_Triangle=("◢" "◣" "◤" "◥")
Spinner_Square=("◰" "◳" "◲" "◱")
Spinner_Quarters=("◴" "◷" "◶" "◵")
Spinner_Halves=("◐" "◓" "◑" "◒")
Spinner_Braille=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")

## @function: spinner(action, label, &spinnerFramesRef[])
##
## @description: Perform an action asynchronously and display
## spinner till action is completed
##
## @param action: The action the execute
## @param label: The label to display while waiting
## @param spinnerRef: In case you feel like a custom spinner, pass a ref to an array of strings
spinner() {
  local frameRef
  local action="${1}"
  local label="${2} "
  local spinnerRef="${3-DEFAULT_SpinnerFrames}"
  local spinnerFrames=$(eval "echo \${!${spinnerRef}[@]}")

  spinnerRun() {
    while true; do
      for frame in ${spinnerFrames[@]}; do
        frameRef="${spinnerRef}[${frame}]"
        echo "${label}${!frameRef}"
        tput cuu1 tput el
        sleep 0.2
      done
    done
    echo -e "\r"
  }

  spinnerRun &
  local spinnerPid=$!
  ${action}
  kill "${spinnerPid}"
}
