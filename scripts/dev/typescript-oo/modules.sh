#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm.git"

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
  github
  jira
)

projectLibs=(
  app-shared
)

executableApps=(
  app
)
