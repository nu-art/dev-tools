#!/bin/bash
source ${BASH_SOURCE%/*}/../../../_core-tools/_source.sh
source ${BASH_SOURCE%/*}/../../core/transpiler.sh
CONST_Debug=true
setTranspilerOutput ${BASH_SOURCE%/*}
addTranspilerClassPath ${BASH_SOURCE%/*}

new ClassA logEntry1
new ClassA logEntry2
new ClassB logEntry3

logEntry3.logMessage = "print log with default error level"
logEntry1.logMessage = "This will be a Debug log"
logEntry2.logMessage = "This will be a Warning log"
#
logEntry3.printLog
logEntry2.logLevel = "Warning"
logEntry2.printLog
#
logEntry1.logLevel = "Debug"
logEntry1.printLog
