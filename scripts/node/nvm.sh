nvm.installAndUseNvmIfNeeded() {
  NVM_DIR="$HOME/.nvm"
  if [[ ! -d "${NVM_DIR}" ]]; then
    logInfo
    bannerInfo "Installing NVM"

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

    if [[ -e "~/.zshrc" ]]; then
      echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.zshrc
      echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.zshrc
    fi
  fi

  # shellcheck source=./$HOME/.nvm
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
  if [[ ! $(nvm.assert) ]] && [[ "v$(cat .nvmrc | head -1)" != "$(nvm current)" ]]; then

    #    nvm deactivate
    #    nvm uninstall v16.13.0
    # shellcheck disable=SC2076
    [[ ! "$(nvm ls | grep "v$(cat .nvmrc | head -1)") | head -1" =~ "v$(cat .nvmrc | head -1)" ]] && echo "nvm install" && nvm install
    nvm use --delete-prefix "v$(cat .nvmrc | head -1)" --silent
    echo "nvm use" && nvm use
  fi
}

nvm.assert() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM Does not exist.. Script should have installed it.. let's figure this out"
  [[ -s ".nvmrc" ]] && return 0

  return 1
}
