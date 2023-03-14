#!/bin/bash

shell.getFileRC() {
  if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
    echo "${HOME}/.zshrc"
  elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
    echo "${HOME}/.bashrc"
  else
    throwError "unknown shell: $SHELL" 2
  fi
}

shell.version() {
  $SHELL --version
}
