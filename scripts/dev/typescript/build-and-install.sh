#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/ci/typescript/_source.sh

source ${BASH_SOURCE%/*}/params.sh
source ${BASH_SOURCE%/*}/help.sh

source .scripts/setup.sh
source .scripts/modules.sh
source .scripts/signature.sh

enforceBashVersion 4.4

appVersion=
nuArtVersion=

#################
#               #
#  DECLARATION  #
#               #
#################

function printVersions() {
    logDebug "Nu-Art version: ${nuArtVersion}"
    logDebug "App version: ${appVersion}"
    executeOnModules printModule
}

function mapModulesVersions() {
    modulesPackageName=()
    modulesVersion=()
    if [[ -e "version-nu-art.json" ]]; then
        nuArtVersion=`getVersionName "version-nu-art.json"`
    fi

    appVersion=`getVersionName "version-app.json"`

    executeOnModules mapModule
}
function mapExistingLibraries() {
    _modules=()
    local module
    for module in "${modules[@]}"; do
        if [[ ! -e "${module}" ]]; then continue; fi
        _modules+=(${module})
    done
    modules=("${_modules[@]}")
}

function purgeModule() {
    logInfo "Purge module: ${1}"
    deleteDir node_modules
    if [[ -e "package-lock.json" ]]; then
        rm package-lock.json
    fi
}

function usingBackend() {
    if [[ ! "${deployBackend}" ]] && [[ ! "${launchBackend}" ]]; then
        echo
        return
    fi

    echo true
}

function usingFrontend() {
    if [[ ! "${deployFrontend}" ]] && [[ ! "${launchFrontend}" ]]; then
        echo
        return
    fi

    echo true
}

function buildModule() {
    local module=${1}

    if [[ `usingFrontend` ]] && [[ ! `usingBackend` ]] && [[ "${module}" == "${backendModule}" ]]; then
        return
    fi

    if [[ `usingBackend` ]] && [[ ! `usingFrontend` ]] && [[ "${module}" == "${frontendModule}" ]]; then
        return
    fi

    compileModule ${module}
}

function testModule() {
    npm run test
}

function linkDependenciesImpl() {
    local module=${1}

    logVerbose
    logInfo "Sorting package json file: ${module}"
    sort-package-json
    throwError "Please install sort-package-json:\n   npm i -g sort-package-json"

    copyFileTo package.json dist/
    logInfo "Linking dependencies sources to: ${module}"
    if [[ `contains "${module}" "${nuArtModules[@]}"` ]] && [[ "${nuArtVersion}" ]]; then
        setVersionName ${nuArtVersion}
    fi

    if [[ `contains "${module}" "${projectModules[@]}"` ]]; then
        setVersionName ${appVersion}

        for otherModule in "${otherModules[@]}"; do
            local target="`pwd`/src/main/${otherModule}"
            local origin="`pwd`/../${otherModule}/src/main/ts"

            createDir ${target}
            deleteDir ${target}

            logDebug "ln -s ${origin} ${target}"
            ln -s ${origin} ${target}
            throwError "Error symlink dependency: ${otherModule}"
        done
    fi

    local i
    for (( i=0; i<${#modules[@]}; i+=1 )); do
        if [[ "${module}" == "${modules[${i}]}" ]]; then break; fi

        if [[ `contains "${modules[${i}]}" "${projectModules[@]}"` ]]; then
            return
        fi

        local modulePackageName="${modulesPackageName[${i}]}"
        if [[ ! "`cat package.json | grep ${modulePackageName}`" ]]; then
            continue;
        fi

        logInfo "Linking ${modules[${i}]} (${modulePackageName}) => ${module}"
        local target="`pwd`/node_modules/${modulePackageName}"
        local origin="`pwd`/../${modules[${i}]}/dist"

        createDir ${target}
        deleteDir ${target}

        logDebug "ln -s ${origin} ${target}"
        ln -s ${origin} ${target}
        throwError "Error symlink dependency: ${modulePackageName}"

        local moduleVersion="${modulesVersion[${i}]}"
        if [[ ! "${moduleVersion}" ]]; then continue; fi

        logDebug "Updating dependency version to ${modulePackageName} => ${moduleVersion}"
        local escapedModuleName=${modulePackageName/\//\\/}

        if [[ `isMacOS` ]]; then
            sed -i '' "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"^${moduleVersion}\"/g" package.json
        else
            sed -i "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"^${moduleVersion}\"/g" package.json
        fi
        throwError "Error updating version of dependency in package.json"
    done
}

function backupPackageJson() {
    cp package.json _package.json
    throwError "Error backing up package.json in module: ${1}"
}

function restorePackageJson() {
    rm package.json
    throwError "Error restoring package.json in module: ${1}"

    mv _package.json package.json
    throwError "Error restoring package.json in module: ${1}"
}

function setupModule() {
    local module=${1}

    function cleanPackageJson() {
        local i
        for (( i=0; i<${#modules[@]}; i+=1 )); do
            local dependencyModule=${modules[${i}]}
            local dependencyPackageName="${modulesPackageName[${i}]}"

            if [[ "${module}" == "${dependencyModule}" ]]; then break; fi
            if [[ ! -e "../${dependencyModule}" ]]; then logWarning "BAH `pwd`/${dependencyModule}"; continue; fi

            local escapedModuleName=${dependencyPackageName/\//\\/}

            if [[ `isMacOS` ]]; then
                sed -i '' "/${escapedModuleName}/d" package.json
            else
                sed -i "/${escapedModuleName}/d" package.json
            fi
        done
    }

    backupPackageJson
    cleanPackageJson

    if [[ "${install}" ]]; then
        trap 'restorePackageJson' SIGINT
            deleteFile package-lock.json
            logVerbose
            logInfo "Installing ${module}"
            logVerbose
            npm install
            throwError "Error installing module"

#            npm audit fix
#            throwError "Error fixing vulnerabilities"
        trap - SIGINT
    fi

    restorePackageJson
}

function executeOnModules() {
    local toExecute=${1}
    local async=${2}

    local i
    for (( i=0; i<${#modules[@]}; i+=1 )); do
        local module="${modules[${i}]}"
        local packageName="${modulesPackageName[${i}]}"
        local version="${modulesVersion[${i}]}"
        if [[ ! -e "./${module}" ]]; then continue; fi

        cd ${module}
            if [[ "${async}" == "true" ]]; then
                ${toExecute} ${module} ${packageName} ${version} &
            else
                ${toExecute} ${module} ${packageName} ${version}
            fi
        cd ..
    done
}

function getModulePackageName() {
    local packageName=`cat package.json | grep '"name":' | head -1 | sed -E "s/.*\"name\".*\"(.*)\",?/\1/"`
    echo "${packageName}"
}

function getModuleVersion() {
    local version=`cat package.json | grep '"version":' | head -1 | sed -E "s/.*\"version\".*\"(.*)\",?/\1/"`
    echo "${version}"
}

function mapModule() {
    local packageName=`getModulePackageName`
    local version=`getModuleVersion`
    modulesPackageName+=(${packageName})
    modulesVersion+=(${version})
}

function printModule() {
    local output=`printf "Found: %-15s %-20s  %s\n" ${1} ${2} v${3}`
    logDebug "${output}"
}

function cloneNuArtModules() {
    local module
    for module in "${nuArtModules[@]}"; do
        if [[ ! -e "${module}" ]]; then
            git clone git@github.com:nu-art-js/${module}.git
        else
            cd ${module}
                git pull
            cd ..
        fi
    done
}

function mergeFromFork() {
    local repoUrl=`gitGetRepoUrl`
    if [[ "${repoUrl}" == "${boilerplateRepo}" ]]; then
        throwError "HAHAHAHA.... You need to be careful... this is not a fork..." 2
    fi

    logInfo "Making sure repo is clean..."
    gitAssertRepoClean
    git remote add public ${boilerplateRepo}
    git fetch public
    git merge public/master
    throwError "Need to resolve conflicts...."

    git submodule update dev-tools
}

function pushNuArt() {
    for module in "${nuArtModules[@]}"; do
        if [[ ! -e "${module}" ]]; then
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        fi
    done

    for module in "${nuArtModules[@]}"; do
        cd ${module}
            gitPullRepo
            gitNoConflictsAddCommitPush ${module} `gitGetCurrentBranch` "${pushNuArtMessage}"
        cd ..
    done
}

function deriveVersionType() {
    local _version=${1}
    case "${_version}" in
        "patch" | "minor" | "major")
            echo ${_version}
            return
        ;;

        "p")
            echo "patch"
            return
        ;;

        *)
            throwError "Bad version type: ${_version}" 2
        ;;
    esac
}

function promoteNuArt() {
    local versionFile="version-nu-art.json"
    local promotionType=`deriveVersionType ${promoteNuArtVersion}`
    local versionName=`getVersionName ${versionFile}`
    nuArtVersion=`promoteVersion ${versionName} ${promotionType}`

    logInfo "Promoting Nu-Art: ${versionName} => ${nuArtVersion}"

    logInfo "Asserting main repo readiness to promote a version..."
    gitAssertBranch master
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull
    logInfo "Main Repo is ready for version promotion"

    for module in "${nuArtModules[@]}"; do
        if [[ ! -e "${module}" ]]; then
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        fi

        cd ${module}
            gitAssertBranch master
            gitAssertRepoClean
            gitFetchRepo
            gitAssertNoCommitsToPull

            if [[ `git tag -l | grep ${nuArtVersion}` ]]; then
                throwError "Tag already exists: v${nuArtVersion}" 2
            fi
        cd ..
    done

    logInfo "Repo is ready for version promotion"
    logInfo "Promoting Libs: ${versionName} => ${nuArtVersion}"
    setVersionName ${nuArtVersion} ${versionFile}
    executeOnModules linkDependenciesImpl

    for module in "${nuArtModules[@]}"; do
        cd ${module}
            gitNoConflictsAddCommitPush ${module} `gitGetCurrentBranch` "Promoted to: v${nuArtVersion}"

            gitTag "v${nuArtVersion}" "Promoted to: v${nuArtVersion}"
            gitPushTags
            throwError "Error pushing promotion tag"
        cd ..
    done

    gitNoConflictsAddCommitPush ${module} `gitGetCurrentBranch` "Promoted infra version to: v${nuArtVersion}"
    gitTag "libs-v${nuArtVersion}" "Promoted libs to: v${nuArtVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"
}

function promoteApps() {
    if [[ ! "${newVersion}" ]]; then
        throwError "MUST specify a new version for the apps... use --set-version=x.y.z" 2
    fi

    logInfo "Asserting repo readiness to promote a version..."
    if [[ `git tag -l | grep ${newVersion}` ]]; then
        throwError "Tag already exists: v${newVersion}" 2
    fi

    gitAssertBranch "${allowedBranchesForPromotion[@]}"
    gitAssertRepoClean
    gitFetchRepo
    gitAssertNoCommitsToPull

    local versionFile="version-app.json"
    local versionName=`getVersionName ${versionFile}`
    logInfo "Promoting Apps: ${versionName} => ${newVersion}"
    setVersionName ${newVersion} ${versionFile}
    executeOnModules linkDependenciesImpl

    local currentBranch=`gitGetCurrentBranch`

    gitNoConflictsAddCommitPush "main-repo" ${currentBranch} "Promoted apps version to: v${newVersion}"
    gitTag "apps-v${newVersion}" "Promoted apps to: v${newVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"
}

function publishNuArt() {
    for module in "${nuArtModules[@]}"; do
        cd ${module}
            logInfo "publishing module: ${module}"
            cp package.json dist/
            cd dist
                npm publish --access public
                throwError "Error publishing module: ${module}"
            cd ..
        cd ..
    done
}

function getFirebaseConfig() {
    logInfo "Fetching config for serving function locally..."
    firebase functions:config:get > .runtimeconfig.json
    throwError "Error while getting functions config"
}

function copyConfigFile() {
    local message=${1}
    local pathTo=${2}
    local envFile=${3}
    local targetFile=${4}
    local envConfigFile="${pathTo}/${envFile}"
    logInfo "${message}"

    if [[ ! -e "${envConfigFile}" ]]; then
        throwError "File not found: ${envConfigFile}" 2
    fi
    cp "${envConfigFile}" ${targetFile}


}

function setEnvironment() {
    logInfo "Setting envType: ${envType}"
    copyConfigFile "Setting firebase.json for env: ${envType}" "./.config" "firebase-${envType}.json" "firebase.json"
    copyConfigFile "Setting .firebaserc for env: ${envType}" "./.config" ".firebaserc-${envType}" ".firebaserc"

    cd ${backendModule}
        copyConfigFile "Setting frontend config.ts for env: ${envType}" "./.config" "config-${envType}.ts" "./src/main/config.ts"
    cd - > /dev/null

    cd ${frontendModule}
        copyConfigFile "Setting frontend config.ts for env: ${envType}" "./.config" "config-${envType}.ts" "./src/main/config.ts"
    cd - > /dev/null

    firebase use `getJsonValueForKey .firebaserc "default"`
}

function compileOnCodeChanges() {
    logDebug "Stop all fswatch listeners..."
    killAllProcess fswatch

    pids=()
    local sourceDirs=()
    for module in ${modules[@]}; do
        if [[ ! -e "./${module}" ]]; then continue; fi
        sourceDirs+=(${module}/src)

        logInfo "Dirt watcher on: ${module}/src => bash build-and-install.sh --flag-dirty=${module}"
        fswatch -o -0 ${module}/src | xargs -0 -n1 -I{} bash build-and-install.sh --flag-dirty=${module} &
        pids+=($!)
    done

    logInfo "Cleaning team on: ${sourceDirs[@]} => bash build-and-install.sh --clean-dirt"
    fswatch -o -0 ${sourceDirs[@]} | xargs -0 -n1 -I{} bash build-and-install.sh --clean-dirt &
    pids+=($!)

    for pid in "${pids[@]}"; do
        wait ${pid}
    done
}

function compileModule() {
    local compileLib=${1}

    if [[ "${cleanDirt}" ]] && [[ ! -e ".dirty" ]]; then
        return
    fi

    if [[ "${clean}" ]]; then
        logVerbose
        clearFolder dist
    fi

    logInfo "${compileLib} - Compiling..."
    npm run build
    throwError "Error compiling:  ${compileLib}"

    cp package.json dist/
    deleteFile .dirty
    logInfo "${compileLib} - Compiled!"
}

function lintModule() {
    local module=${1}

    logInfo "${module} - linting..."
    tslint --project tsconfig.json
    throwError "Error while linting:  ${module}"

    logInfo "${module} - linted!"
}

#################
#               #
#    PREPARE    #
#               #
#################

# Handle recursive sync execution
if [[ ! "${1}" =~ "dirt" ]]; then
    signature
    printCommand "$@"
fi

extractParams "$@"

if [[ "${dirtyLib}" ]]; then
    touch ${dirtyLib}/.dirty
    logInfo "flagged ${dirtyLib} as dirty... waiting for cleaning team"
    exit 0
fi

if [[ "${cleanDirt}" ]]; then
    logDebug "Cleaning team is ready, stalling 3 sec for dirt to pile up..."
    sleep 3s
else
    printDebugParams ${debug} "${params[@]}"
fi


#################
#               #
#   EXECUTION   #
#               #
#################

if [[ "${#modules[@]}" == 0 ]]; then
    modules+=(${nuArtModules[@]})
    modules+=(${projectModules[@]})
fi

if [[ "${mergeOriginRepo}" ]]; then
    bannerInfo "Merge Origin"
    mergeFromFork
    logInfo "Merged from origin boilerplate... DONE"
    exit 0
fi

if [[ "${cloneNuArt}" ]]; then
    bannerInfo "Clone Nu-Art"
    cloneNuArtModules
    bash $0 --setup
fi

mapExistingLibraries
mapModulesVersions

# BUILD

if [[ "${purge}" ]]; then
    bannerInfo "purge"
    executeOnModules purgeModule
fi

if [[ "${envType}" ]]; then
    bannerInfo "set env"
    setEnvironment
fi

if [[ "${setup}" ]]; then
    bannerInfo "setup"
    executeOnModules setupModule
fi

if [[ "${linkDependencies}" ]]; then
    bannerInfo "link dependencies"
    executeOnModules linkDependenciesImpl

    mapModulesVersions
    printVersions
fi


if [[ "${build}" ]]; then
    executeOnModules buildModule
fi

if [[ "${lint}" ]]; then
    bannerInfo "lint"
    executeOnModules lintModule
fi

if [[ "${test}" ]]; then
    bannerInfo "test"
    executeOnModules testModule
fi

# PRE-Launch and deploy

if [[ "${newVersion}" ]]; then
    bannerInfo "promote apps"
    promoteApps
fi

# LAUNCH

if [[ "${launchBackend}" ]]; then
    bannerInfo "launchBackend"

    npm list -g nodemon > /dev/null
    throwError "nodemon package is missing... Please install nodemon:\n npm i -g nodemon"

    setupBackend
    cd ${backendModule}
        if [[ "${launchFrontend}" ]]; then
            npm run serve &
        else
            npm run serve
        fi
    cd ..
fi

if [[ "${launchFrontend}" ]]; then
    bannerInfo "launchFrontend"

    cd ${frontendModule}
        if [[ "${launchBackend}" ]]; then
            npm run dev &
        else
            npm run dev
        fi
    cd ..
fi

# Deploy

if [[ "${deployBackend}" ]] || [[ "${deployFrontend}" ]]; then
    bannerInfo "deployBackend || deployFrontend"

    if [[ ! "${envType}" ]]; then
        throwError "MUST set env while deploying!!" 2
    fi

    firebaseProject=`getJsonValueForKey .firebaserc "default"`

    if [[ "${deployBackend}" ]]; then
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only functions
        throwError "Error while deploying functions"
    fi

    if [[ "${deployFrontend}" ]]; then
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only hosting
        throwError "Error while deploying hosting"
    fi
fi

# OTHER

if [[ "${pushNuArtMessage}" ]]; then
    bannerInfo "pushNuArtMessage"
    pushNuArt
fi

if [[ "${promoteNuArtVersion}" ]]; then
    bannerInfo "promoteNuArtVersion"

    gitAssertOrigin "${boilerplateRepo}"
    promoteNuArt
fi

if [[ "${publish}" ]]; then
    bannerInfo "publish"

    gitAssertOrigin "${boilerplateRepo}"
    publishNuArt
    executeOnModules setupModule
    gitNoConflictsAddCommitPush ${module} `gitGetCurrentBranch` "built with new dependencies version"
fi

if [[ "${listen}" ]]; then
    bannerInfo "listen"

    compileOnCodeChanges
fi