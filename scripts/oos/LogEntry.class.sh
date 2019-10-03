#!/bin/bash
source `pwd`/../_core-tools/_source.sh


class_LogEntry() {
    declare logMessage
    declare logLevel=Error

    LogEntry.printLog(){
        log${LogEntry_logLevel} "${LogEntry_logMessage}"
    }
}

