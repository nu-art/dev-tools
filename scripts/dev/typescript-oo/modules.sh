#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm.git"

allowedBranchesForPromotion=(
  master
  staging
  dev
  move-to-ir
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
  jira
  bug-report
  github
  file-upload
  google-services
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

executableApps=(
  app
)
