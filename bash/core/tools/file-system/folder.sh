#!/bin/bash

## @function: folder.workingDirectory()
##
## @description: Returns the name of the current directory
##
## @return: string - basename of $PWD
folder.workingDirectory() {
  echo "${PWD##*/}"
}

## @function: folder.myDir(depth)
##
## @description: Gets the directory path of the calling script
##
## @return: string - absolute path
folder.myDir() {
  cd "$(dirname "${BASH_SOURCE[${1:-1}]}")" && pwd
}

## @function: folder.exists(path)
##
## @description: Checks whether the path exists
##
## @return: true if exists
folder.exists() {
  [[ -e "$1" ]] && echo true
}

## @function: folder.isDirectory(path)
##
## @description: Checks whether the path is a directory
##
## @return: true if it's a directory
folder.isDirectory() {
  [[ -d "$1" ]] && echo true
}

## @function: folder.create(path)
##
## @description: Creates a folder if it doesn't exist
folder.create() {
  local dir="$1"
  [[ -e "$dir" && ! -d "$dir" ]] && echo "[ERROR] Path exists but is not a directory: $dir" >&2 && return 1
  mkdir -p "$dir"
}

## @function: folder.clear(path)
##
## @description: Deletes all contents of a folder, without deleting the folder itself
folder.clear() {
  local dir="$1"
  [[ -d "$dir" ]] && rm -rf "$dir"/* "$dir"/.* 2>/dev/null || echo "[WARN] Not a directory: $dir" >&2
}

## @function: folder.delete(path)
##
## @description: Deletes the given folder and its contents
folder.delete() {
  local dir="$1"
  [[ -d "$dir" ]] && rm -rf "$dir"
}

## @function: folder.list(subdir)
##
## @description: Lists immediate subdirectories of given path (default: current dir)
folder.list() {
  local path="${1:-.}"
  find "$path" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;
}


