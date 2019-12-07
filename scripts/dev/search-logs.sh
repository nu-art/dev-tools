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
folder=${1}
echo "Searching for crashes in folder: ${folder}"

pushd "${folder}"
pwd
    for file in logs*.zip; do
        [[ -e "$file" ]] || continue
        # ... rest of the loop body

        index=`echo ${file} | sed -E "s/logs-(..).zip/\1/"`
        unzip ${file} -d temp-${index} > NUL
        mv temp-${index}/logs-00.txt logs-${index}.txt
        rm ${file}
        rm -rf temp-${index}
    done


    mv logcat.txt logcat.txt.00
    for file in logcat.txt*; do
        [[ -e "$file" ]] || continue
        # ... rest of the loop body

        outputName=`echo ${file} | sed -E "s/logcat\.txt\.(..)/logcat-\1.txt/"`
        echo ${outputName}
        mv ${file} ${outputName}
    done

    echo "Bluetooth:"
#    grep -rnw '.' --include=\*.txt -e 'Application Starting'
    grep -E 'Turning bluetooth adapter' -rnw '.' --include=\*.txt
    grep -E '=> ERROR_BLUETOOTH__REBOOT' -rnw '.' --include=\*.txt
    echo

#    echo "Application started:"
#    grep -rnw '.' --include=\*.txt -e 'Application Starting'
#    echo

    echo "On boot completed"
    grep -rnw '.' --include=\*.txt -e 'Boot completed'
    echo
#
#    echo "Process Killed by system:"
#    grep -rnw '.' --include=\*.txt -e 'Process com.ir.ai.kyou'
#    echo
#
#    echo "Process crashed:"
#    grep -rnw '.' --include=\*.txt -e 'Crash on thread'
#    grep -rnw '.' --include=\*.txt -e 'FATAL'
#    echo
#
#    echo "Process died:"
#    grep -rnw '.' --include=\*.txt -e 'SIG'
#    echo
#    echo
#    echo
#
#
#    echo "Searching for exceptions:"
#    grep -rnw '.' --include=\*.txt -e 'Exception'
#    echo

popd
