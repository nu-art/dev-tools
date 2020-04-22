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

getFolderId {
    local folderName="$1"

    folderId=`gdrive list --name-width 0 --no-header --query "mimeType='application/vnd.google-apps.folder'andname='${folderName}'"`
    folderId=`echo ${folderId} | awk '{print $1}'`

	throwError "Error getting the folder id"

	echo "${folderId}"
}

getFileId {
    local fileName="$1"

    local fileId=`gdrive list --name-width 0 --no-header --query "name='${fileName}'"`
    fileId=`echo ${fileId} | awk '{print $1}'`

	throwError "Error getting the file id"

	echo "${fileId}"
}

upload {
    local fileName="$1"
    local parentFolder="$2"

    if [[ "$parentFolder" != "" ]]; then
        gdrive upload --parent "${parentFolder}" "${fileName}"
    else
        gdrive upload "${fileName}"
    fi

	throwError "Error uploading ${fileName} => ${parentFolder}"
}