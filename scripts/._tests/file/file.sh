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
DIR_test_file=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR_test_file}/../_tests.sh"

test.file.prepare() {
  rm -rf output
  mkdir output
}

test.file.cleanup() {
  rm -rf output
}

test.file.copy() {
  local originName=origin.txt
  local targetName=target.txt

  echo ZE ZEVEL > ./output/${originName}
  file.copy "./output/${originName}" "./output" "${targetName}" -s
  cat "./output/${targetName}"
}

test.file.findMatches() {
  local originName=origin.txt
  local pathToFile=./output/${originName}
  echo 'ZE "$ZEVEL"' > "${pathToFile}"
  echo '"$ZEVEL" ZEZE' >> "${pathToFile}"

  local toRet=()
  toRet+=($(file.findMatches "${pathToFile}" '"(\$.*?)"'))
  echo "${toRet[@]}"
}

test.file.pathToFile() {
  local pathToFile="$(file.pathToFile "/pah/zevel/male.ashpa")"
  echo "${pathToFile}"
}

assertCommand '/pah/zevel' "test.file.pathToFile"
#assertCommand "ZE ZEVEL" "test.file.copy" "test.file.prepare" "test.file.cleanup"
#assertCommand '"$ZEVEL" "$ZEVEL"' "test.file.findMatches" "test.file.prepare" "test.file.cleanup"
