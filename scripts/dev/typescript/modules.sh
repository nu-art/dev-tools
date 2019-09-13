#!/bin/bash

boilerplateRepo="git@github.com:nu-art-js/typescript-boilerplate.git"

frontendModule=app-frontend
backendModule=app-backend
allowedBranchesForPromotion=(master staging dev)

projectModules=(app-backend app-frontend)

otherModules=(app-shared)

nuArtModules=(ts-common testelot thunder storm)
modules=()
