#!/bin/bash

ClassA() {
    declare logMessage
    declare logLevel=Error

    _printLog() {
        log${logLevel} "${logMessage}"
    }
}

