#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm.git"

buildSteps=(printDependencyTree purge clean install link generate compile lint test publish launch deploy)

allowedBranchesForPromotion=(
  master
  prod
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
