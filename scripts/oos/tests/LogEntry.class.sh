#!/bin/bash

LogEntry() {
    declare logMessage
    declare logLevel=Error

    _printLog() {
        log${logLevel} "${logMessage}"
    }
}

