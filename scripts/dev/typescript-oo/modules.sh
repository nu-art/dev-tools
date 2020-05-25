#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

allowedBranchesForPromotion=(
  master
  staging
)

tsLibs=(
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

projectLibs=(
  app-shared
)

backendApps=(
  app-backend
)

frontendApps=(
  app-frontend
)
