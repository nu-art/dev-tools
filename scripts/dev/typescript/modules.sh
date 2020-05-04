#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend

allowedBranchesForPromotion=(master staging)

projectModules=(app-backend app-frontend)
projectLibraries=(app-shared)

thunderstormLibraries=()
