#!/bin/bash

killProcess() {
  logInfo "Killing processes ${*:2}"
  kill "-${1}" "${@:2}"
  trap "logWarning \"Wait for graceful exit... of ${*:2}\"" SIGINT
  wait "${@:2}"
  logDebug "Processes killed ${*:2}"
  trap - SIGINT
}
