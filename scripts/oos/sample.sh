#!/bin/bash

source ./transpiler.sh

new LogEntry logEntry1
new LogEntry logEntry2
new LogEntry logEntry3


logEntry3.logMessage = "Pah Zevel 3"
logEntry1.logMessage = "Pah Zevel 1"
logEntry2.logMessage = "Pah Zevel 2"

logEntry3.printLog
logEntry2.logLevel = "Warning"
logEntry2.printLog

logEntry1.logLevel = "Debug"
logEntry1.printLog
