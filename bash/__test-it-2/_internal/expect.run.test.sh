#!/bin/bash

test_echo_to_equal_success() {
  expect.run "echo hello" to.equal "hello"
}

test_expect_fail_with_output() {
  expect.run "expect.run 'echo hello' to.equal 'world'" to.fail.with 1 "expected: 'world'"
}

test_to_contain_fail() {
  expect.run "expect 'abc' to.contain 'xyz'" to.fail.with 1 "expected to contain: 'xyz'"
}

test_to_match_fail() {
  expect.run "expect 'abc' to.match '[0-9]+'" to.fail.with 1 "expected to match regex: '[0-9]+'"
}

test_to_be_empty_fail() {
  expect.run "expect 'non-empty' to.be.empty" to.fail.with 1 "empty value"
}
