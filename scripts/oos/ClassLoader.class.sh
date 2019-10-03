#!/bin/bash
source `pwd`/../_core-tools/_source.sh


ClassLoader() {
    declare logMessage
    declare logLevel=Error

    printLog() {
        log${logLevel} "${logMessage}"
    }
}

