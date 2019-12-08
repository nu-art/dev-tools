#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/ci/typescript/_source.sh

source ${BASH_SOURCE%/*}/params.sh
source ${BASH_SOURCE%/*}/help.sh

[[ -e ".scripts/setup.sh" ]] && {
    source .scripts/setup.sh
}
[[ -e ".scripts/signature.sh" ]] && {
    source .scripts/signature.sh
}
[[ -e ".scripts/modules.sh" ]] && {
    source .scripts/modules.sh
} || {
    source ${BASH_SOURCE%/*}/modules.sh
}

enforceBashVersion 4.4

appVersion=
nuArtVersion=

#################
#               #
#  DECLARATION  #
#               #
#################

function signatureThunderstorm() {
    clear
    logVerbose "${Gray}             _____ _                     _                    _                                      ${NoColor}"
    logVerbose "${Gray} -------    |_   _| |__  _   _ _ __   __| | ___ _ __      ___| |_ ___  _ __ _ __ ___    ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | '_ \| | | | '_ \ / _\` |/ _ \ '__|____/ __| __/ _ \| '__| '_ \` _ \ ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | | | | |_| | | | | (_| |  __/ | |_____\__ \ || (_) | |  | | | | | |  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      |_| |_| |_|\__,_|_| |_|\__,_|\___|_|       |___/\__\___/|_|  |_| |_| |_|  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------                                                                                ${Gray}   ------- ${NoColor}"
    logVerbose
    sleep 1s
}

function assertNodePackageInstalled() {
    local package=${1}

    logDebug "Verifying package installed ${package}..."
    npm list -g ${package} | grep ${package}> error 2>&1
    local code=$?
    local version=`cat error | tail -1 | sed -E "s/.*${package}@(.*)/\1/"`
    rm error

    [[ "${code}" != "0" ]] && {
        throwError "Missing node module '${package}'  Please run:      npm i -g ${package}@latest" ${code}
    }

    logInfo "Found package ${package} == ${version}"
}

function printVersions() {
    logDebug "Nu-Art version: ${nuArtVersion}"
    logDebug "App version: ${appVersion}"
    executeOnModules printModule
}

function mapModulesVersions() {
    modulesPackageName=()
    modulesVersion=()
    [[ ! "${nuArtVersion}" ]] && [[ -e "version-nu-art.json" ]] && {
        nuArtVersion=`getVersionName "version-nu-art.json"`
    }

    [[ "${newAppVersion}" ]] && {
        appVersion=${newAppVersion}
    }

    [[ ! "${appVersion}" ]] && {
        local tempVersion=`getVersionName "version-app.json"`
        local splitVersion=(${tempVersion//./ })
        for (( arg=0; arg<3; arg+=1 )); do
            [[ ! "${splitVersion[${arg}]}" ]] && {
                splitVersion[${arg}]=0
            }
        done
        appVersion=`joinArray "." ${splitVersion[@]}`
    }

    executeOnModules mapModule
}
function mapExistingLibraries() {
    _modules=()
    local module
    for module in "${modules[@]}"; do
        [[ ! -e "${module}" ]] && { continue; }
        _modules+=(${module})
    done
    modules=("${_modules[@]}")
}

function purgeModule() {
    logInfo "Purge module: ${1}"
    deleteDir node_modules
    [[ -e "package-lock.json" ]] && {
        rm package-lock.json
    }
}

function usingBackend() {
    [[ ! "${deployBackend}" ]] && [[ ! "${launchBackend}" ]] && [[ ! "${launchTmux}" ]] && {
        echo
        return
    }

    echo true
}

function usingFrontend() {
    [[ ! "${deployFrontend}" ]] && [[ ! "${launchFrontend}" ]] && [[ ! "${launchTmux}" ]] && {
        echo
        return
    }

    echo true
}

function buildModule() {
    local module=${1}

    [[ `usingFrontend` ]] && [[ ! `usingBackend` ]] && [[ "${module}" == "${backendModule}" ]] && {
        return
    }

    [[ `usingBackend` ]] && [[ ! `usingFrontend` ]] && [[ "${module}" == "${frontendModule}" ]] && {
        return
    }

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

    copyFileToFolder package.json dist/
    logInfo "Linking dependencies sources to: ${module}"
    [[ `contains "${module}" "${nuArtModules[@]}"` ]] && [[ "${nuArtVersion}" ]] && {
        logInfo "Setting version '${nuArtVersion}' to module: ${module}"
        setVersionName ${nuArtVersion}
    }

    [[ `contains "${module}" "${projectModules[@]}"` ]] && {
        logInfo "Setting version '${appVersion}' to module: ${module}"
        setVersionName ${appVersion}

        for otherModule in "${otherModules[@]}"; do
            local target="`pwd`/src/main/${otherModule}"
            local origin="`pwd`/../${otherModule}/src/main/ts"

            createDir ${target}

            chmod -R 777  ${target}
            deleteDir ${target}

            logDebug "cp -r ${origin} ${target}"
            cp -r ${origin} ${target}
            [[ "${readOnly}" ]] && {
                chmod -R 444  ${target}/*
            }
            throwError "Error symlink dependency: ${otherModule}"
        done
    }
    local BACKTO=`pwd`
    cd ..
        mapModulesVersions
    cd ${BACKTO}

    local i
    for (( i=0; i<${#modules[@]}; i+=1 )); do
        [[ "${module}" == "${modules[${i}]}" ]] && { break; }

        [[ `contains "${modules[${i}]}" "${projectModules[@]}"` ]] && {
            return
        }

        local modulePackageName="${modulesPackageName[${i}]}"
        [[ ! "`cat package.json | grep ${modulePackageName}`" ]] && {
            continue;
        }

        logInfo "Linking ${modules[${i}]} (${modulePackageName}) => ${module}"
        local target="`pwd`/node_modules/${modulePackageName}"
        local origin="`pwd`/../${modules[${i}]}/dist"

        createDir ${target}

        chmod -R 777 ${target}
        deleteDir ${target}

        logDebug "ln -s ${origin} ${target}"
        ln -s ${origin} ${target}
        throwError "Error symlink dependency: ${modulePackageName}"

        local moduleVersion="${modulesVersion[${i}]}"
        [[ ! "${moduleVersion}" ]] && { continue; }

        logDebug "Updating dependency version to ${modulePackageName} => ${moduleVersion}"
        local escapedModuleName=${modulePackageName/\//\\/}

        [[ `isMacOS` ]] && {
            sed -i '' "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"^${moduleVersion}\"/g" package.json
        } || {
            sed -i "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"^${moduleVersion}\"/g" package.json
        }
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

            [[ "${module}" == "${dependencyModule}" ]] && { break; }
            [[ ! -e "../${dependencyModule}" ]] && { logWarning "BAH `pwd`/${dependencyModule}"; continue; }

            local escapedModuleName=${dependencyPackageName/\//\\/}

            [[ `isMacOS` ]] && {
                sed -i '' "/${escapedModuleName}/d" package.json
            } || {
                sed -i "/${escapedModuleName}/d" package.json
            }
        done
    }

    backupPackageJson
    cleanPackageJson

    [[ "${install}" ]] && {
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
    }

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
        [[ ! -e "./${module}" ]] && { continue; }

        cd ${module}
            [[ "${async}" == "true" ]] && {
                ${toExecute} ${module} ${packageName} ${version} &
            } || {
                ${toExecute} ${module} ${packageName} ${version}
            }
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

function cloneThunderstormModules() {
    local module
    for module in "${nuArtModules[@]}"; do
        [[ ! -e "${module}" ]] && {
            git clone git@github.com:nu-art-js/${module}.git
        } || {
            cd ${module}
                git pull
            cd ..
        }
    done
}

function mergeFromFork() {
    local repoUrl=`gitGetRepoUrl`
    [[ "${repoUrl}" == "${boilerplateRepo}" ]] && {
        throwError "HAHAHAHA.... You need to be careful... this is not a fork..." 2
    }

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
        [[ ! -e "${module}" ]] && {
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        }
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
        [[ ! -e "${module}" ]] && {
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        }

        cd ${module}
            gitAssertBranch master
            gitAssertRepoClean
            gitFetchRepo
            gitAssertNoCommitsToPull

            [[ `git tag -l | grep ${nuArtVersion}` ]] && {
                throwError "Tag already exists: v${nuArtVersion}" 2
            }
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
    [[ ! "${newAppVersion}" ]] && {
        throwError "MUST specify a new version for the apps... use --set-version=x.y.z" 2
    }

    appVersion=${newAppVersion}
    logInfo "Asserting repo readiness to promote a version..."
    [[ `git tag -l | grep ${appVersion}` ]] && {
        throwError "Tag already exists: v${appVersion}" 2
    }

    gitAssertBranch "${allowedBranchesForPromotion[@]}"
    gitFetchRepo
    gitAssertNoCommitsToPull

    local versionFile="version-app.json"
    local versionName=`getVersionName ${versionFile}`
    logInfo "Promoting Apps: ${versionName} => ${appVersion}"
    setVersionName ${appVersion} ${versionFile}
    executeOnModules linkDependenciesImpl

    local currentBranch=`gitGetCurrentBranch`

    gitTag "v${appVersion}" "Promoted apps to: v${appVersion}"
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

    [[ ! -e "${envConfigFile}" ]] && {
        throwError "File not found: ${envConfigFile}" 2
    }
    cp "${envConfigFile}" ${targetFile}


}

function setEnvironment() {
    logInfo "Setting envType: ${envType}"
    copyConfigFile "Setting firebase.json for env: ${envType}" "./.config" "firebase-${envType}.json" "firebase.json"
    copyConfigFile "Setting .firebaserc for env: ${envType}" "./.config" ".firebaserc-${envType}" ".firebaserc"
    [[ -e ${backendModule} ]] && {
        cd ${backendModule}
            copyConfigFile "Setting frontend config.ts for env: ${envType}" "./.config" "config-${envType}.ts" "./src/main/config.ts"
        cd - > /dev/null
    }

    [[ -e ${frontendModule} ]] && {
        cd ${frontendModule}
            copyConfigFile "Setting frontend config.ts for env: ${envType}" "./.config" "config-${envType}.ts" "./src/main/config.ts"
        cd - > /dev/null
    }

    firebase use `getJsonValueForKey .firebaserc "default"`
}

function compileOnCodeChanges() {
    logDebug "Stop all fswatch listeners..."
    killAllProcess fswatch

    pids=()
    local sourceDirs=()
    for module in ${modules[@]}; do
        [[ ! -e "./${module}" ]] && { continue; }
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

    [[ "${cleanDirt}" ]] && [[ ! -e ".dirty" ]] && {
        return
    }

    [[ "${clean}" ]] && {
        logVerbose
        clearFolder dist
    }

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
[[ ! "${1}" =~ "dirt" ]] && {
    signature
    printCommand "$@"
}

extractParams "$@"

[[ "${dirtyLib}" ]] && {
    touch ${dirtyLib}/.dirty
    logInfo "flagged ${dirtyLib} as dirty... waiting for cleaning team"
    exit 0
}

[[ "${cleanDirt}" ]] && {
    logDebug "Cleaning team is ready, stalling 3 sec for dirt to pile up..."
    sleep 3s
} || {
    printDebugParams ${debug} "${params[@]}"
}


#################
#               #
#   EXECUTION   #
#               #
#################

[[ "${printEnv}" ]] && {
    assertNodePackageInstalled typescript
    assertNodePackageInstalled tslint
    assertNodePackageInstalled firebase-tools
    assertNodePackageInstalled sort-package-json
    logDebug "node version: "`node -v`
    logDebug "npm version: "`npm -v`
    logDebug "bash version: "`getBashVersion`
    exit 0
}

[[ "${#modules[@]}" == 0 ]] && {
    [[ "${buildThunderstorm}" ]] && {
        modules+=(${nuArtModules[@]})
    }
    modules+=(${projectModules[@]})
}

[[ "${mergeOriginRepo}" ]] && {
    bannerInfo "Merge Origin"
    mergeFromFork
    logInfo "Merged from origin boilerplate... DONE"
    exit 0
}

[[ "${cloneThunderstorm}" ]] && {
    bannerInfo "Clone Nu-Art"
    cloneThunderstormModules
    bash $0 --setup
}

mapExistingLibraries
mapModulesVersions

# BUILD
[[ "${purge}" ]] && {
    bannerInfo "purge"
    executeOnModules purgeModule
}

[[ "${envType}" ]] && {
    bannerInfo "set env"
    setEnvironment
}

[[ "${setup}" ]] && {
    assertNodePackageInstalled typescript
    assertNodePackageInstalled firebase-tools
    assertNodePackageInstalled sort-package-json
    assertNodePackageInstalled nodemon
    assertNodePackageInstalled tslint

    bannerInfo "setup"
    executeOnModules setupModule
}

[[ "${linkDependencies}" ]] && {
    bannerInfo "link dependencies"
    executeOnModules linkDependenciesImpl

    mapModulesVersions
    printVersions
}


[[ "${build}" ]] && {
    executeOnModules buildModule
}

[[ "${lint}" ]] && {
    bannerInfo "lint"
    executeOnModules lintModule
}

[[ "${testModules}" ]] && {
    bannerInfo "test"
    executeOnModules testModule
}

# PRE-Launch and deploy

[[ "${newAppVersion}" ]] && {
    bannerInfo "promote apps"
    promoteApps
}

# LAUNCH
[[ "${runBackendTests}" ]] && {
    cd ${backendModule}
        npm run test
    cd ..
    exit 0
}

[[ "${launchBackend}" ]] && {
    bannerInfo "launchBackend"
    cd ${backendModule}
        [[ "${launchFrontend}" ]] && {
            npm run serve &
        } || {
            npm run serve
        }
    cd ..
}

[[ "${launchFrontend}" ]] && {
    bannerInfo "launchFrontend"

    cd ${frontendModule}
        [[ "${launchBackend}" ]] && {
            npm run dev &
        } || {
            npm run dev
        }
    cd ..
}

[[ "${launchTmux}" ]] && {
    bannerInfo "launchTmux"

    command -v tmux >/dev/null 2>&1 && {

        runBackend="cd ${backendModule} && npm run serve; read -p 'Process finished'"
        runFrontend="cd ${frontendModule} && npm run dev; read -p 'Process finished'"

        tmux new -d -s my-session "$runBackend" \; split-window -h "$runFrontend" \; attach \;

        exit 0;
    } || {
        echo >&2 "I require tmux but it's not installed. Aborting.";
    }
}


# Deploy

[[ "${deployBackend}" ]] || [[ "${deployFrontend}" ]] && {
    bannerInfo "deployBackend || deployFrontend"

    [[ ! "${envType}" ]] && {
        throwError "MUST set env while deploying!!" 2
    }

    firebaseProject=`getJsonValueForKey .firebaserc "default"`

    [[ "${deployBackend}" ]] && [[ -e ${backendModule} ]] && {
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only functions
        throwError "Error while deploying functions"
    }

    [[ "${deployFrontend}" ]] && [[ -e ${frontendModule} ]] && {
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only hosting
        throwError "Error while deploying hosting"
    }
}

# OTHER

[[ "${pushNuArtMessage}" ]] && {
    bannerInfo "pushNuArtMessage"
    pushNuArt
}

[[ "${promoteNuArtVersion}" ]] && {
    bannerInfo "promoteNuArtVersion"

    gitAssertOrigin "${boilerplateRepo}"
    promoteNuArt
}

[[ "${publish}" ]] && {
    bannerInfo "publish"

    gitAssertOrigin "${boilerplateRepo}"
    publishNuArt
    executeOnModules setupModule
    gitNoConflictsAddCommitPush ${module} `gitGetCurrentBranch` "built with new dependencies version"
}

[[ "${listen}" ]] && {
    bannerInfo "listen"

    compileOnCodeChanges
}
