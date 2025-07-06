#!/bin/bash

## @function: expect(actual, ...assertion)
##
## @description: Entry point for fluent assertions with literal input
expect() {
  local actual="$1"
  shift
  "$@" "$actual"
}

## @function: expect.run(command, ...assertion)
##
## @description: Entry point for assertions on evaluated command output
expect.run() {
  local cmd="$1"
  shift

  # Set global so to.fail.with can access it
  __expect_last_command="$cmd"

  local actual
  actual="$(eval "$cmd")"
  "$@" "$actual"
}

## @function: to.equal(expected, actual)
##
## @description: Asserts that actual equals expected and exits on failure
##
## @usage: expect "$actual" to.equal "$expected"
to.equal() {
  local expected="$1"
  local actual="$2"
  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    fail "\n  expected: '$expected'\n  actual:   '$actual'"
  fi
}

## @function: to.not.equal(expected, actual)
##
## @description: Asserts that actual does NOT equal expected
##
## @usage: expect "$actual" to.not.equal "$expected"
to.not.equal() {
  local expected="$1"
  local actual="$2"

  if [[ "$actual" == "$expected" ]]; then
    fail "\n  expected: '$expected' to not match:\n  actual:   '$actual'"
  else
    return 0
  fi
}

## @function: to.contain(substring, actual)
##
## @description: Asserts that actual contains the given substring
##
## @usage: expect "$actual" to.contain "$substring"
to.contain() {
  local substring="$1"
  local actual="$2"

  if [[ "$actual" == *"$substring"* ]]; then
    return 0
  else
    fail "\n  expected to contain: '$substring'\n  actual:             '$actual'"
  fi
}

## @function: to.not.contain(substring, actual)
##
## @description: Asserts that actual does NOT contain the given substring
##
## @usage: expect "$actual" to.not.contain "$substring"
to.not.contain() {
  local substring="$1"
  local actual="$2"

  if [[ "$actual" != *"$substring"* ]]; then
    return 0
  else
    fail "\n  expected to NOT contain: '$substring'\n  actual:               '$actual'"
  fi
}

## @function: to.match(regex, actual)
##
## @description: Asserts that actual matches the given regex
##
## @usage: expect "$actual" to.match "$regex"
to.match() {
  local regex="$1"
  local actual="$2"

  if [[ "$actual" =~ $regex ]]; then
    return 0
  else
    fail "\n  expected to match regex: '$regex'\n  actual:                '$actual'"
  fi
}

## @function: to.not.match(regex, actual)
##
## @description: Asserts that actual does NOT match the given regex
##
## @usage: expect "$actual" to.not.match "$regex"
to.not.match() {
  local regex="$1"
  local actual="$2"

  if [[ ! "$actual" =~ $regex ]]; then
    return 0
  else
    fail "\n  expected NOT to match regex: '$regex'\n  actual:                  '$actual'"
  fi
}

## @function: to.be.empty(actual)
##
## @description: Asserts that the actual input is empty. For strings, it checks for "". For arrays, it checks for 0 elements.
##
## @usage: expect "" to.be.empty
##         expect "${my_array[@]}" to.be.empty
##         expect "$(ls empty-dir)" to.be.empty
to.be.empty() {
  local actual=("$@")
  if [[ ${#actual[@]} -eq 0 || (( ${#actual[@]} -eq 1 && "${actual[0]}" == "" )) ]]; then
    return 0
  else
    fail "\n  expected empty value (string or array)\n  actual: '${actual[*]}'"
  fi
}

## @function: to.be.true(actual)
##
## @description: Asserts that the actual value is non-empty
##
## @usage: expect "$actual" to.be.true
to.be.true() {
  local actual="$1"

  if [[ -n "$actual" ]]; then
    return 0
  else
    fail "\n  expected truthy value\n  actual: '$actual'"
  fi
}

## @function: to.be.false(actual)
##
## @description: Asserts that the actual value is falsy — empty, "false", or "0"
##
## @usage: expect "$actual" to.be.false
to.be.false() {
  local actual="$1"

  if [[ -z "$actual" || "$actual" == "false" || "$actual" == "0" ]]; then
    return 0
  else
    fail "\n  expected falsy value (empty, 'false', or '0')\n  actual: '$actual'"
  fi
}

## @function: to.be.number(actual)
##
## @description: Asserts that the actual value is a valid number
##
## @usage: expect "$actual" to.be.number
to.be.number() {
  local actual="$1"

  if [[ "$actual" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    return 0
  else
    fail "\n  expected numeric value\n  actual: '$actual'"
  fi
}

## @function: to.have.length(expectedLength, actual)
##
## @description: Asserts that the actual value has expected string length
##
## @usage: expect "$actual" to.have.length 5
to.have.length() {
  local expected="$1"
  local actual="$2"
  local actual_len=${#actual}

  if [[ "$actual_len" -eq "$expected" ]]; then
    return 0
  else
    fail "\n  expected length: $expected\n  actual length:   $actual_len"
  fi
}

## @function: to.include.all(item1, item2, ..., actual)
##
## @description: Asserts that the actual string includes all given substrings
##
## @usage: expect "$actual" to.include.all one two three
to.include.all() {
  local actual="${@: -1}"
  for needle in "${@:1:$#-1}"; do
    if [[ "$actual" != *"$needle"* ]]; then
      fail "\n  expected to include: '$needle'\n  actual:             '$actual'"
    fi
  done
  return 0
}

## @function: to.fail.with(expectedCode, expectedMessage)
##
## @description: Asserts that the last command fails with expected code and message
##
## @usage: expect.run "some command" to.fail.with 1 "error message"
to.fail.with() {
  local expected_code="$1"
  local expected_output="$2"

  local output
  output=$(eval "$__expect_last_command" 2>&1)
  local code=$?

  if [[ "$code" != "$expected_code" ]]; then
    fail "\n  expected exit code: $expected_code\n  actual exit code:   $code\n  output:\n$output"
  fi

  if [[ "$output" != *"$expected_output"* ]]; then
    fail "\n  expected output to contain:\n'$expected_output'\n  actual output:\n$output"
  fi

  return 0
}

## @function: fail(message)
##
## @description: Prints failure message and exits with error
fail() {
  echo -e "[FAIL] $1" >&2
  exit 1
}
