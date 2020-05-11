#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend

allowedBranchesForPromotion=(master staging)

resolveThunderstormLibs() {
  local _thunderstormLibraries=(
    ts-common
    testelot
    neural
    firebase
    thunderstorm
    db-api-generator
    storm
    live-docs
    user-account
    permissions
    push-pub-sub
    bug-report
  )

  thunderstormLibraries=()
  for lib in "${_thunderstormLibraries[@]}"; do
    [[ ! -e "${lib}" ]] && continue
    thunderstormLibraries+=("${lib}")
  done
}

resolveThunderstormLibs

projectLibraries=(
  ${thunderstormLibraries[@]}
  app-shared
)

projectModules=(
  app-backend
  app-frontend
)
