#!/bin/bash

declare -A timerMap

function startTimer() {
    local key=${1}
    timerMap[$key]=$SECONDS
}

function calcDuration() {
    local key=${1}
    local startedTimestamp=${timerMap[$key]}
    if [ ! "${startedTimestamp}" ]; then startedTimestamp=0; fi

    local duration=$(( $SECONDS - ${startedTimestamp} ))
    local seconds=$(($duration % 60))
    if [ "$seconds" -lt 10 ]; then seconds="0$seconds"; fi

    local min=$(($duration / 60))
    if [ "$min" -eq 0 ]; then min=00; elif [ "$min" -lt 10 ]; then min="0$min"; else min="$min"; fi
    echo ${min}:${seconds}
}

startTimer "rootTimer"
