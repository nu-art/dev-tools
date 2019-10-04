#!/bin/bash
source `pwd`/../_core-tools/_source.sh
CONST_Debug=

function _logVerbose() {
    if [[ ! "${CONST_Debug}" ]]; then
        return
    fi

    >&2 logVerbose $@
}

function _logDebug() {
    if [[ ! "${CONST_Debug}" ]]; then
        return
    fi

    >&2 logDebug $@
}

function _logInfo() {
    if [[ ! "${CONST_Debug}" ]]; then
        return
    fi

    >&2 logInfo $@
}

function _logWarning() {
    if [[ ! "${CONST_Debug}" ]]; then
        return
    fi

    >&2 logWarning $@
}

function _logError() {
    if [[ ! "${CONST_Debug}" ]]; then
        return
    fi

    >&2 logError $@
}