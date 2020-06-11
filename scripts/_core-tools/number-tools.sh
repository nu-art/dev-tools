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

## @function: number_assertNumeric(number, defaultValue?)
##
## @description:
##    Asserts that the given "number" is numeric, other wise return the defaultValue.
##    If no default value is provided, this will throw an error NaN...
##
## @return: The numeric value give, or the default value if provided
number_assertNumeric() {
  local number="${1}"
  local defaultValue="${2}"

  if [[ ! "${number}" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
    [[ ! "${defaultValue}" ]] && throwError "'${number}' is NaN" 2
    [[ ! "${defaultValue}" =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]] && throwError "Default provided '${defaultValue}' is NaN" 2

    echo "${defaultValue}"
    return
  fi

  echo "${number}"
}

## @function: number_random(seed)
##
## @description:
##    Generate a random number between 0 - ${seed}
##
## @return: The generated random number
number_random() {
  local seed=$(number_assertNumeric "${1}" 100)
  echo "$(((RANDOM * RANDOM * RANDOM) % seed))"
}
