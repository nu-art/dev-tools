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
source ${BASH_SOURCE%/*}/../android/_source.sh

executeCommand() {
  local command=${1}
  local message=${2}
  if [[ ! "${message}" ]]; then message="Running: ${1}"; fi
  logInfo "${message}"
  eval "${command}"
  throwError "${message}"
}

logInfo "DID YOU REMEMBER TO COMMENT OUT THE PASSWORD?"

signature "Jenkins Upgrade"
executeCommand "sudo service jenkins stop"
executeCommand "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -"
executeCommand "sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'"
executeCommand "sudo apt-get update"
executeCommand "sudo apt-get install jenkins"
executeCommand "sudo service jenkins start"
