#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/navigation.sh"

before_each() {
  ORIG_DIR="$(pwd)"
  mkdir -p .tmp-nav/test-subdir
}

after_each() {
  cd "$ORIG_DIR"
  rm -rf .tmp-nav
}

test_nav_cd_into_folder() {
  nav.cd .tmp-nav/test-subdir
  expect "$(pwd)" to.match "/.*/.tmp-nav/test-subdir"
}

test_nav_cd_back_to_previous() {
  local before="$(pwd)"
  cd .tmp-nav/test-subdir
  nav.cd- >/dev/null
  expect "$(pwd)" to.equal "$before"
}

test_nav_pushd_and_popd() {
  nav.pushd .tmp-nav/test-subdir
  expect "$(pwd)" to.match "/.*/.tmp-nav/test-subdir"
  nav.popd
  expect "$(pwd)" to.equal "$ORIG_DIR"
}
