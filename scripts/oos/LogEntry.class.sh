#!/bin/bash
source `pwd`/../_core-tools/_source.sh


function create() {
    declare logMessage
    declare logLevel

    LogEntry.printLog(){
        log`LogEntry.logLevel` "`LogEntry.logMessage`"
    }
}

