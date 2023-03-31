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

InstallerDMG() {

  declare label
  declare requiresMount=true
  declare outputFile
  declare inZipFile
  declare downloadUrl
  declare volumeToInstall

  _cleanup() {
    deleteFile "${outputFile}"
  }

  _onAborted() {
    echo
    echo
    this.cleanup
    throwError "${label} download aborted by user" 2
  }

  _download() {
    [[ "${inZipFile}" ]] && [[ -e "${inZipFile}" ]] && return
    [[ -e "${outputFile}" ]] && return

    trap 'this.onAborted' SIGINT
    logInfo "Downloading ${label}..."
    curl "${downloadUrl}" -o "${outputFile}"
    trap - SIGINT

    [[ ! -e "${outputFile}" ]] && throwError "Download completed, but no file found at: ${outputFile}"
  }

  _unzip() {
    [[ ! ${inZipFile} ]] && return
    if [[ ! -e "${inZipFile}" ]]; then
      logInfo "Unzipping ${outputFile}"
      unzip "${outputFile}" -d "${label}" > /dev/null
      throwError "Error Unzipping archive: ${outputFile}"

      deleteFile "${outputFile}"
    fi

    [[ ! "${requiresMount}" ]] && volumeToInstall=./${label}
    outputFile="${inZipFile}"
  }

  _mount() {
    [[ ! "${requiresMount}" ]] && return

    logInfo "Mounting ${outputFile}"
    local mountoutput=$(hdiutil mount "${outputFile}")
    throwError "Error mounting: ${outputFile}"

    local pah=($(echo "${mountoutput}" | tail -1))
    local length=$((${#pah[@]} - 1))
    volumeToInstall="${pah[${length}]}"
  }

  _run() {
    logInfo "Installing ${label}"
    sleep 1
    rsync -a "${volumeToInstall}"/*.app /Applications/
    throwError "Error copying *.app into application folder"
  }

  _unmount() {
    [[ ! "${requiresMount}" ]] && folder.delete "${volumeToInstall}" && return

    logInfo "Unmouting ${label}"
    hdiutil detach -quiet "${volumeToInstall}"
  }

  _install() {
    this.download
    this.unzip
    this.mount
    this.run
    this.unmount
    this.cleanup
  }
}
