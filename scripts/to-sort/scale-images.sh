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

targetWidth=${1}
targetHeight=${2}
ratio=`bc -l <<< "scale=3; ${targetWidth}/${targetHeight}"`
echo "Target dimension: w=${targetWidth} h=${targetHeight} R=${ratio}"
mkdir output

function listFilesImpl() {
    ls -lf > list.txt
    local files=()
    local filesName

    while IFS='' read -r line || [[ -n "$line" ]]; do
        for word in ${line}; do
            filesName=${word}
        done

        filesName=`echo ${filesName} | sed -E 's/\///'`

        if [[ ! -d "${filesName}" ]] && ([[ "${filesName}" =~ ".png" ]] || [[ "${filesName}" =~ ".jpg" ]]); then
            files[${#files[*]}]="${filesName}"
            continue
        fi

    done < list.txt

    rm list.txt
    echo "${files[@]}"
}

function scaleImageTo() {
    local fileName=${1}

    echo "Processing image: ${fileName}"
    local output=`sips -g pixelWidth ${fileName}`
    imageWidth=`echo ${output} | sed -E 's/.* pixel.*: (.*)/\1/'`

    local output=`sips -g pixelHeight ${fileName}`
    imageHeight=`echo ${output} | sed -E 's/.* pixel.*: (.*)/\1/'`

    echo "  Dimensions: w=${imageWidth} h=${imageHeight}"
    local cropWidth=`bc -l <<< "scale=0; ${imageHeight}*${ratio}"`
    cropWidth=${cropWidth%.*}
    local cropHeight="${imageHeight}"

    echo "  Crop Dimensions: w=${cropWidth} h=${cropHeight}"

    sips -c ${cropWidth} ${cropHeight} ${fileName} --out output

    sips -z ${targetWidth} ${targetHeight} output/${fileName} --out output
}

files=$(listFilesImpl)
files=(${files//,/ })
for fileName in "${files[@]}"; do
    scaleImageTo ${fileName}
done