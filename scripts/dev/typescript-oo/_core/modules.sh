#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm.git"

buildSteps=(
  setEnvironment
  printDependencyTree
  cleanEnv
  purge
  clean
  install
  link
  generate
  preBuild
  compile
  checkCyclicImports
  generateDocs
  lint
  test
  publish
  launch
  deploy
)

allowedBranchesForPromotion=(
  prod
  master
  prod
  staging
  dev
)

tsLibs=(
  ts-common
  ts-styles
  google-services
  firebase
  thunderstorm
  ts-pdf
  slack
  live-docs
  user-account
  permissions
  ts-focused-object
  ts-messaging
  ts-workspace
  push-pub-sub
  jira
  bug-report
  github
  file-upload
  ts-openai
  schema-to-types
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
