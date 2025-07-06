#!/bin/bash

## @function: nav.cd(dir)
##
## @description: Navigates into the given directory
nav.cd() {
  local pathToDir=$1
  [[ -z "$pathToDir" ]] && echo "[WARN] path is empty" >&2 && return 2
  cd "$pathToDir" > /dev/null 2>&1 || echo "[WARN] $(pwd)/$pathToDir folder does not exist" >&2
}

## @function: nav.cd..()
##
## @description: Moves one directory up
nav.cd..() {
  cd ..
}

## @function: nav.cd-()
##
## @description: Goes back to previous directory
nav.cd-() {
  cd -
}

## @function: nav.pushd(dir)
##
## @description: Pushes the current directory onto stack and moves to the target
nav.pushd() {
  local pathToDir=$1
  [[ -z "$pathToDir" ]] && echo "[WARN] path is empty" >&2 && return 2
  pushd "$pathToDir" > /dev/null 2>&1 || echo "[WARN] $(pwd)/$pathToDir folder does not exist" >&2
}

## @function: nav.popd()
##
## @description: Pops directory stack and moves back
nav.popd() {
  popd > /dev/null 2>&1 || echo "[WARN] no directory to pop" >&2
}


