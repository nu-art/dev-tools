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
  sleep 5
  echo "Got param: ${1} - END"
}

spinner "actionToRun test" "Default"
spinner "actionToRun test" "Dot" Spinner_Dot
spinner "actionToRun test" "Vertical" Spinner_Vertical
spinner "actionToRun test" "Horizontal" Spinner_Horizontal
spinner "actionToRun test" "Arrows" Spinner_Arrows
spinner "actionToRun test" "WHAT" Spinner_WHAT
spinner "actionToRun test" "WHAT2" Spinner_WHAT2
spinner "actionToRun test" "Triangle" Spinner_Triangle
spinner "actionToRun test" "Square" Spinner_Square
spinner "actionToRun test" "Quarters" Spinner_Quarters
spinner "actionToRun test" "Halves" Spinner_Halves
spinner "actionToRun test" "Braille" Spinner_Braille