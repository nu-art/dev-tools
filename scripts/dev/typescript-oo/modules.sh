#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend

allowedBranchesForPromotion=(master staging)

thunderstormLibraries=(
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

projectLibraries=(
  ${thunderstormLibraries[@]}
  app-shared
)

projectModules=(
  app-backend
  app-frontend
)
