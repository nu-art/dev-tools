#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm.git"

buildSteps=(
  printDependencyTree
  cleanEnv
  purge
  clean
  install
  link
  generate
  compile
  generateDocs
  lint
  test
  publish
  launch
  deploy
)

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
  google-services
  firebase
  thunderstorm
  db-api-generator
  storm
  live-docs
  user-account
  ts-workspace
  permissions
  push-pub-sub
  jira
  bug-report
  github
  file-upload
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

deployableApps=(
  app-backend
  app-frontend
)

executableApps=(
  app
)
