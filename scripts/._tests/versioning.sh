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
source "${DIR}/_tests.sh"

assert "0.0.2" "promoteVersion 0.0.1 patch"
assert "0.1.1" "promoteVersion 0.1 patch 3"
assert "0.1.1" "promoteVersion 0.1 patch 2"
assert "0.1.1" "promoteVersion 0.1 patch"

assert "0.2" "promoteVersion 0.1 minor"
assert "0.3" "promoteVersion 0.2 minor 1"
assert "0.2.0" "promoteVersion 0.1 minor 3"
assert "1.0.0" "promoteVersion 0.2 major 3"
assert "1.0" "promoteVersion 0.2 major"
assert "1.0.0" "promoteVersion 0.2.0 major"
assert "1.0" "promoteVersion 0.2 major 2"
assert "1" "promoteVersion 0.2 major 1"

printSummary