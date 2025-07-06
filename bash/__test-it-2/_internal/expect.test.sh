#!/bin/bash

test_to_equal_success() {
  expect "hello" to.equal "hello"
}

test_to_not_equal_success() {
  expect "hello" to.not.equal "world"
}

test_to_contain_success() {
  expect "hello world" to.contain "hello"
}

test_to_match_success() {
  expect "hello123" to.match "hello[0-9]+"
}

test_to_be_empty_success() {
  expect "" to.be.empty
}

test_to_not_contain_success() {
  expect "hello world" to.not.contain "bye"
}

test_to_not_match_success() {
  expect "hello123" to.not.match "^[0-9]+$"
}

test_to_include_all_success() {
  expect "this is a test string" to.include.all "this" "test"
}

test_to_be_true_success() {
  expect "non-empty" to.be.true
}

test_to_be_false_success() {
  expect "" to.be.false
  expect "false" to.be.false
  expect "0" to.be.false
}

test_to_be_number_success() {
  expect "42.5" to.be.number
  expect "-12" to.be.number
  expect "0" to.be.number
}

test_to_have_length_success() {
  expect "hello" to.have.length 5
}

test_to_be_empty_string_success() {
  expect "" to.be.empty
}

test_to_be_empty_array_success() {
  local empty_array=()
  expect "${empty_array[@]}" to.be.empty
}

test_to_be_empty_command_output_success() {
  mkdir -p .tmp-empty-dir
  expect "$(ls .tmp-empty-dir)" to.be.empty
  rmdir .tmp-empty-dir
}
