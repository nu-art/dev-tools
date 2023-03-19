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
DIR_CoreTools=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

CHAR_TAB="$(printf '\t')"

source ${DIR_CoreTools}/colors.sh
source ${DIR_CoreTools}/logger.sh
source ${DIR_CoreTools}/time.sh
source ${DIR_CoreTools}/signature.sh
source ${DIR_CoreTools}/spinner.sh

source ${DIR_CoreTools}/tools.sh
source ${DIR_CoreTools}/error-handling.sh
source ${DIR_CoreTools}/cli-params.sh
source ${DIR_CoreTools}/folder-filters.sh
source ${DIR_CoreTools}/file-tools.sh
source ${DIR_CoreTools}/folder-tools.sh
source ${DIR_CoreTools}/array-tools.sh
source ${DIR_CoreTools}/string-tools.sh
source ${DIR_CoreTools}/number-tools.sh
source ${DIR_CoreTools}/versioning.sh
source ${DIR_CoreTools}/help-tools.sh
source ${DIR_CoreTools}/prompt-tools.sh
source ${DIR_CoreTools}/shell.sh
source ${DIR_CoreTools}/debugger.sh
