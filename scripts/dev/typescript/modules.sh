#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/thunderstorm-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend

allowedBranchesForPromotion=(master staging dev)

projectModules=(app-backend app-frontend)
nuArtModules=(ts-common testelot thunder storm live-docs user-login)
linkedSourceModules=(app-shared)

dependencyModules=()
