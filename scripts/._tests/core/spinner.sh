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
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${DIR}/../_tests.sh"

actionToRun() {
  echo "Got param: ${1} - START"
  sleep 1
  echo "Got param: 1"
  sleep 1
  echo "Got param: 2"
  sleep 1
  echo "Got param: 3"
  sleep 1
  echo "Got param: 4"
  sleep 1
  echo "Got param: 5"
  echo "Got param: ${1} - END"
}

spinner "actionToRun Default" "test"
spinner "actionToRun Dot" "test" Spinner_Dot
spinner "actionToRun Vertical" "test" Spinner_Vertical
spinner "actionToRun Horizontal" "test" Spinner_Horizontal
spinner "actionToRun Arrows" "test" Spinner_Arrows
spinner "actionToRun WHAT" "test" Spinner_WHAT
spinner "actionToRun WHAT2" "test" Spinner_WHAT2
spinner "actionToRun Triangle" "test" Spinner_Triangle
spinner "actionToRun Square" "test" Spinner_Square
spinner "actionToRun Quarters" "test" Spinner_Quarters
spinner "actionToRun Halves" "test" Spinner_Halves
spinner "actionToRun Braille" "test" Spinner_Braille