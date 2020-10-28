#!/bin/bash

ExecutablePackage() {
  extends class NodePackage

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return

    logInfo "Launching: ${folderName}"
    node "./${outputDir}/"${ts_fileToExecute}
    throwError "execution failed ./${outputDir}/"${ts_fileToExecute}
  }
}
