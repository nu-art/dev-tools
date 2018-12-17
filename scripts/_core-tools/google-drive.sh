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

function getFolderId {
    local folderName="$1"

    folderId=`gdrive list --name-width 0 --no-header --query "mimeType='application/vnd.google-apps.folder'andname='${folderName}'"`
    folderId=`echo ${folderId} | awk '{print $1}'`

	checkExecutionError "Error getting the folder id"

	echo "${folderId}"
}

function getFileId {
    local fileName="$1"

    local fileId=`gdrive list --name-width 0 --no-header --query "name='${fileName}'"`
    fileId=`echo ${fileId} | awk '{print $1}'`

	checkExecutionError "Error getting the file id"

	echo "${fileId}"
}

function upload {
    local fileName="$1"
    local parentFolder="$2"

    if [ "$parentFolder" != "" ]; then
        gdrive upload --parent "${parentFolder}" "${fileName}"
    else
        gdrive upload "${fileName}"
    fi

	checkExecutionError "Error uploading ${fileName} => ${parentFolder}"
}