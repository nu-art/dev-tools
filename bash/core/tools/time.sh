#!/bin/bash

## @private: Internal associative map for timers
declare -A time_map=()

## @function: time.start(key)
##
## @description: Starts a timer with the given key
##
## @param: key - Identifier to track time duration under
## @return: void
time.start() {
  local key="$1"
  time_map["$key"]=$SECONDS
}

## @function: time.duration(key)
##
## @description: Calculates and returns elapsed time (mm:ss) since key timer was started
##
## @param: key - Identifier of previously started timer
## @return: Formatted duration string "MM:SS"
time.duration() {
  local key="$1"
  local start="${time_map[$key]:-0}"

  local duration=$((SECONDS - start))
  local seconds=$((duration % 60))
  local minutes=$((duration / 60))

  printf "%02d:%02d\n" "$minutes" "$seconds"
}

## Auto-start default root timer
time.start "root"

