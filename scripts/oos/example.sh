#!/bin/bash

# include class header
. new.sh

# create class object
new LogEntry logEntry1
new LogEntry logEntry2

# use object methods

logEntry1.logMessage = "Pah Zevel"
logEntry1.logLevel = "Debug"
logEntry1.printLog

logEntry2.logMessage = "Pah Zevel2"
logEntry2.logLevel = "Warning"
logEntry2.printLog


#function create() { logEntry2.property() { if [[ "$2" == "=" ]]; then setVariableName $1 "$3"; else echo "${!1}"; fi }
#    local logMessage=; function logEntry2.logMessage() { if [[ "$1" == "=" ]]; then logEntry2.property logMessage = "$2"; else logEntry2.property logMessage; fi }
#    local logLevel=; function logEntry2.logLevel() { if [[ "$1" == "=" ]]; then logEntry2.property logLevel = "$2"; else logEntry2.property logLevel; fi }
#    logLevel=Error
#    logEntry2.printLog(){
#        log${logLevel} "${logMessage}"
#    }
#}
