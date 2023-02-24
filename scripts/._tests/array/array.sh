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
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/../_tests.sh"
arrayRemoveTest1() {
  local pah=("value1" "value2" "value3" "value4")
  array_remove pah value3 value4
  echo "${pah[@]}"
}

arrayRemoveTest2() {
  local pah=("value1" "value2" "value3" "value4" "value4")
  array_remove pah value3 value4
  echo "${pah[@]}"
}

arraySetVarTest1() {
  local pah=("value1" "value2")
  array_setVariable zevel "${pah[@]}"
  echo "${zevel[@]}"
}

arrayMapperTest1() {
  mapper() {
    local input=${1}
    string_replaceAll "-" "_" "${input}"
  }

  local pah=("valu-e1" "val--ue-2")
  array_map pah zevel mapper
  echo "${zevel[@]}"
}

assertCommand "value1 value2" "arrayRemoveTest1"
assertCommand "value1 value2" "arrayRemoveTest2"
assertCommand "value1 value2" "arraySetVarTest1"
assertCommand "valu_e1 val__ue_2" "arrayMapperTest1"
