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

source ${DIR}/colors.sh
source ${DIR}/logger.sh
source ${DIR}/time.sh
source ${DIR}/signature.sh

source ${DIR}/tools.sh
source ${DIR}/error-handling.sh
source ${DIR}/cli-params.sh
source ${DIR}/folder-filters.sh
source ${DIR}/file-tools.sh
source ${DIR}/folder-tools.sh
source ${DIR}/array-tools.sh
source ${DIR}/string-tools.sh
source ${DIR}/number-tools.sh
source ${DIR}/versioning.sh
source ${DIR}/help-tools.sh
