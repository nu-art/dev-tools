assertNVM() {
  [[ ! $(isFunction nvm) ]] && throwError "NVM Does not exist.. Script should have installed it.. let's figure this out"
  [[ -s ".nvmrc" ]] && return 0

  return 1
}
