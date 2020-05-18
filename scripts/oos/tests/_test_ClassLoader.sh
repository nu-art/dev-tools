#!/bin/bash
source ${BASH_SOURCE%/*}/../../_core-tools/_source.sh
source ${BASH_SOURCE%/*}/../core/transpiler.sh
setTranspilerOutput ${BASH_SOURCE%/*}
addTranspilerClassPath ${BASH_SOURCE%/*}
new LogEntry logEntry1
#new LogEntry logEntry2
#new LogEntry logEntry3
#
#
#logEntry3.logMessage = "print log with default error level"
#logEntry1.logMessage = "This will be a Debug log"
#logEntry2.logMessage = "This will be a Warning log"
#
#logEntry3.printLog
#logEntry2.logLevel = "Warning"
#logEntry2.printLog
#
#logEntry1.logLevel = "Debug"
#logEntry1.printLog
