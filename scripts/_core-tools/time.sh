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
timerMap=()

startTimer() {
  local key=${1}
  timerMap[$key]=$SECONDS
}

calcDuration() {
  local key=${1}
  local startedTimestamp=${timerMap[$key]}
  if [[ ! "${startedTimestamp}" ]]; then startedTimestamp=0; fi

  local duration=$(($SECONDS - ${startedTimestamp}))
  local seconds=$(($duration % 60))
  if [[ "$seconds" -lt 10 ]]; then seconds="0$seconds"; fi

  local min=$(($duration / 60))
  if [[ "$min" -eq 0 ]]; then min=00; elif [[ "$min" -lt 10 ]]; then min="0$min"; else min="$min"; fi
  echo ${min}:${seconds}
}

startTimer "rootTimer"
