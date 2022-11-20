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

deployableApps=(
  app-backend
  app-frontend
)

executableApps=(
  app
)
