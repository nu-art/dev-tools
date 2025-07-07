#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/time.sh"

test_time_start_and_duration_zero() {
  time.start "test"
  sleep 1
  local duration="$(time.duration "test")"
  expect "$duration" to.match "00:0[1-9]"
}

test_time_multiple_keys_independent() {
  time.start "t1"
  sleep 1
  time.start "t2"
  sleep 1  # ensure t1 has passed at least a second
  local duration1="$(time.duration "t1")"
  local duration2="$(time.duration "t2")"
  expect "$duration1" to.match "00:0[1-9]"
  expect "$duration2" to.match "00:0[0-1]"
}
