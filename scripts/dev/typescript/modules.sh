#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend

allowedBranchesForPromotion=(master staging dev)

projectModules=(app-backend app-frontend)
projectLibraries=(app-shared)

thunderstormLibraries=(ts-common testelot firebase thunderstorm db-api-generator storm live-docs user-account permissions push-pub-sub)
