#!/bin/bash

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${DIR}/folder.sh"

before_each() {
  ORIG_DIR="$(pwd)"
  mkdir -p .tmp-fs/nested
}

after_each() {
  cd "$ORIG_DIR"
  rm -rf .tmp-fs
}

test_folder_workingDirectory_returns_basename() {
  cd .tmp-fs
  expect "$(folder.workingDirectory)" to.equal ".tmp-fs"
}

test_folder_myDir_returns_script_dir() {
  expect "$(folder.myDir)" to.contain "/core/tools/file-system"
}

test_folder_exists_positive() {
  expect "$(folder.exists .tmp-fs)" to.equal "true"
}

test_folder_isDirectory_true() {
  expect "$(folder.isDirectory .tmp-fs)" to.equal "true"
}

test_folder_create_and_delete() {
  folder.create .tmp-fs/new-dir
  expect "$(folder.exists .tmp-fs/new-dir)" to.equal "true"
  folder.delete .tmp-fs/new-dir
  expect "$(folder.exists .tmp-fs/new-dir)" to.equal ""
}

test_folder_clear_clears_content() {
  mkdir -p .tmp-fs/clear-me/inner
  touch .tmp-fs/clear-me/file.txt
  folder.clear .tmp-fs/clear-me
  expect "$(ls .tmp-fs/clear-me | wc -l)" to.equal "0"
}

test_folder_list_outputs_subdirs() {
  mkdir -p .tmp-fs/a .tmp-fs/b
  local out=$(folder.list .tmp-fs)
  expect "$out" to.contain "a"
  expect "$out" to.contain "b"
}
