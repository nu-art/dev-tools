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
allFolders() {
  echo true
}

allGitFolders() {
  local module=${1}
  [[ ! -e "${module}/.git" ]] && return
  echo true
}

gitFolders() {
  local module=${1}
  [[ "${module}" == "dev-tools" ]] && return
  [[ ! -e "${module}/.git" ]] && return
  echo true
}

moduleFolder() {
  # shellcheck disable=SC2076
  [[ "$(cat "${1}/build.gradle" | grep com.android.application)" =~ "com.android.application" ]] && echo
  echo true
}

androidAppsFolder() {
  # shellcheck disable=SC2076
  [[ ! "$(cat "${1}/build.gradle" | grep com.android.application)" =~ "com.android.application" ]] && return
  echo true
}

allGradleFolders() {
  [[ ! -e "${1}/build.gradle" ]] || [[ -e "${1}/settings.gradle" ]] && return
  echo true
}