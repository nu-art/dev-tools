#!/bin/bash
source `pwd`/../_core-tools/_source.sh


LogEntry() {
    declare logMessage
    declare logLevel=Error

    LogEntry.printLog(){
        log${logLevel} "${logMessage}"
    }
}

