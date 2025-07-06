#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/array.sh"

test_array_contains_found() {
  local arr=("value1" "value2" "value3")
  expect "$(array.contains value2 "${arr[@]}")" to.equal "true"
}

test_array_remove_simple() {
  local arr=("value1" "value2" "value3" "value4")
  array.remove arr value3 value4
  expect "${arr[*]}" to.equal "value1 value2"
}

test_array_remove_duplicates() {
  local arr=("value1" "value2" "value3" "value4" "value4")
  array.remove arr value3 value4
  expect "${arr[*]}" to.equal "value1 value2"
}

test_array_set_variable() {
  local source=("value1" "value2")
  array.setVariable result "${source[@]}"
  expect "${result[*]}" to.equal "value1 value2"
}

test_array_filter_duplicates() {
  local arr=("value1" "value2" "value2" "value2" "value3" "value2" "value1")
  array.filterDuplicates arr
  expect "${arr[*]}" to.equal "value1 value2 value3"
}

test_array_map_with_string_replace() {
  mapper() {
    echo "${1//-/_}"
  }
  local arr=("valu-e1" "val--ue-2")
  array.map arr result mapper
  expect "${result[*]}" to.equal "valu_e1 val__ue_2"
}
