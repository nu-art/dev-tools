#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/string.sh"

test_string_endsWith_success() {
  expect "$(string.endsWith "hello-world" "world")" to.equal "true"
}

test_string_startsWith_success() {
  expect "$(string.startsWith "hello-world" "hello")" to.equal "true"
}

test_string_substring_basic() {
  expect "$(string.substring "abcdef" 1 3)" to.equal "bcd"
}

test_string_contains_success() {
  expect "$(string.contains "foobar" "oba")" to.equal "true"
}

test_string_replace_once() {
  expect "$(string.replace foo bar "foo baz foo")" to.equal "bar baz foo"
}

test_string_replace_all() {
  expect "$(string.replaceAll foo bar "foo baz foo")" to.equal "bar baz bar"
}

test_string_join_with_dash() {
  expect "$(string.join - a b c)" to.equal "a-b-c"
}
