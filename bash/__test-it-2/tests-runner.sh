#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/expect.sh"

FILE_NAME_FILTER=""
TEST_NAME_FILTER=""
OUTPUT_FILE=""

PASS_COUNT=0
FAIL_COUNT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE_NAME_FILTER="$2"
      shift 2
      ;;
    --grep)
      TEST_NAME_FILTER="$2"
      shift 2
      ;;
    --out)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

find_test_files() {
  find . -type f -name "*.test.sh" | sort | grep -E ".*${FILE_NAME_FILTER}.*"
}

collect_tests() {
  local all_tests=()
  for test_file in $(find_test_files); do
    mapfile -t funcs < <(grep -Eo '^test_[a-zA-Z0-9_]+' "$test_file")

    if [[ -n "$TEST_NAME_FILTER" ]]; then
      funcs=($(printf "%s\n" "${funcs[@]}" | grep -E ".*${TEST_NAME_FILTER}.*"))
    fi

    if [[ "${#funcs[@]}" -gt 0 ]]; then
      all_tests+=("${funcs[@]}")
    fi
  done

  echo "${#all_tests[@]}"
}

run_test_file() {
  local test_file="$1"

  mapfile -t TEST_FUNCS < <(grep -Eo '^test_[a-zA-Z0-9_]+' "$test_file")

  if [[ -n "$TEST_NAME_FILTER" ]]; then
    # shellcheck disable=SC2207
    TEST_FUNCS=($(printf "%s\n" "${TEST_FUNCS[@]}" | grep -E ".*${TEST_NAME_FILTER}.*"))
  fi

  [[ "${#TEST_FUNCS[@]}" -eq 0 ]] && return

  echo
  echo "# Running tests from file: $test_file"

  # shellcheck disable=SC1090
  source "${test_file}"

  if declare -F before > /dev/null; then before; fi

  for test_fn in "${TEST_FUNCS[@]}"; do
    if declare -F before_each > /dev/null; then before_each; fi

    if output=$("$test_fn" 2>&1); then
      echo "ok   $TEST_COUNTER - $test_fn"
      ((PASS_COUNT++))
    else
      echo "not ok $TEST_COUNTER - $test_fn"
      echo "$output" | sed 's/^/#   /'
      ((FAIL_COUNT++))
    fi

    ((TEST_COUNTER++))

    if declare -F after_each > /dev/null; then after_each; fi
    unset -f "$test_fn"
  done

  if declare -F after > /dev/null; then after; fi

  unset -f before 2>/dev/null
  unset -f after 2>/dev/null
  unset -f before_each 2>/dev/null
  unset -f after_each 2>/dev/null
}

# --- Entry Point ---

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  exec > "$OUTPUT_FILE"
fi

echo "TAP version 13"

TOTAL_TESTS=$(collect_tests)
echo "1..$TOTAL_TESTS"

TEST_COUNTER=1
for test_file in $(find_test_files); do
  run_test_file "$test_file"
done

# --- Summary ---
echo "#"
echo "# Tests:   $TOTAL_TESTS"
echo "# Passed:  $PASS_COUNT"
echo "# Failed:  $FAIL_COUNT"
echo "#"

exit $(( FAIL_COUNT > 0 ? 1 : 0 ))
