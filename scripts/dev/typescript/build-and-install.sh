#!/bin/bash

source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/ci/typescript/_source.sh

source ${BASH_SOURCE%/*}/params.sh
source ${BASH_SOURCE%/*}/help.sh

[[ -e ".scripts/setup.sh" ]] && source .scripts/setup.sh
[[ -e ".scripts/signature.sh" ]] && source .scripts/signature.sh

source ${BASH_SOURCE%/*}/modules.sh
[[ -e ".scripts/modules.sh" ]] && source .scripts/modules.sh
enforceBashVersion 4.4

appVersion=
nuArtVersion=
modules=()

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

    if [[ "${code}" != "0" ]]; then
        throwError "Missing node module '${package}'  Please run:      npm i -g ${package}@latest" ${code}
    fi

    logInfo "Found package ${package} == ${version}"
}

function printVersions() {
    logDebug
    logDebug "Nu-Art version: ${nuArtVersion}"
    logDebug "App version: ${appVersion}"
    logDebug
    local output=`printf "       %-20s %-25s  %s\n" "Folder" "Package" "Version"`
    logWarning "${output}"
    executeOnModules printModule
}


function printModule() {
    local output=`printf "Found: %-20s %-25s  %s\n" ${1} ${2} v${3}`
    logDebug "${output}"
}


function mapModulesVersions() {
    modulesPackageName=()
    modulesVersion=()
    if [[ ! "${nuArtVersion}" ]] && [[ -e "version-nu-art.json" ]]; then
        nuArtVersion=`getVersionName "version-nu-art.json"`
    fi

    if [[ "${newAppVersion}" ]]; then
        appVersion=${newAppVersion}
    fi

    if [[ ! "${appVersion}" ]]; then
        local tempVersion=`getVersionName "version-app.json"`
        local splitVersion=(${tempVersion//./ })
        for (( arg=0; arg<3; arg+=1 )); do
            if [[ ! "${splitVersion[${arg}]}" ]];then
                splitVersion[${arg}]=0
            fi
        done
        appVersion=`joinArray "." ${splitVersion[@]}`
    fi

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

function linkSourcesImpl() {
    local module=${1}

    logVerbose
    logInfo "Sorting package json file: ${module}"
    sort-package-json
    throwError "Please install sort-package-json:\n   npm i -g sort-package-json"

    copyFileToFolder package.json dist/
    logInfo "Linking dependencies sources to: ${module}"
    if [[ `contains "${module}" "${thunderstormLibraries[@]}"` ]] && [[ "${nuArtVersion}" ]]; then
        logInfo "Setting version '${nuArtVersion}' to module: ${module}"
        setVersionName ${nuArtVersion}
    fi

    if [[ `contains "${module}" "${projectModules[@]}"` ]]; then
        logInfo "Setting version '${appVersion}' to module: ${module}"
        setVersionName ${appVersion}

        for otherModule in "${linkedSourceModules[@]}"; do
            local target="`pwd`/src/main/${otherModule}"
            local origin="`pwd`/../${otherModule}/src/main/ts"

            createDir ${target}

            chmod -R 777  ${target}
            deleteDir ${target}

            logDebug "cp -r ${origin} ${target}"
            cp -r ${origin} ${target}
            if [[ "${readOnly}" ]]; then
                chmod -R 444  ${target}/*
            fi
            throwError "Error symlink dependency: ${otherModule}"
        done
    fi
}

function linkDependenciesImpl() {
    local module=${1}

    local BACKTO=`pwd`
    cd ..
        mapModulesVersions
    cd "${BACKTO}"

    local i
    for (( i=0; i<${#modules[@]}; i+=1 )); do
        if [[ "${module}" == "${modules[${i}]}" ]]; then break; fi

        [[ `contains "${modules[${i}]}" "${projectModules[@]}"` ]] && break;

        local modulePackageName="${modulesPackageName[${i}]}"
        [[ ! "`cat package.json | grep ${modulePackageName}`" ]] && continue;

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
        if [[ ! "${moduleVersion}" ]]; then continue; fi

        local escapedModuleName=${modulePackageName/\//\\/}
        moduleVersion=`replaceInText "([0-9+]\\.[0-9]+\\.)[0-9]+" "\10" "${moduleVersion}"`
        logDebug "Updating dependency version to ${modulePackageName} => ${moduleVersion}"

#        replaceAllInFile "\"${escapedModuleName}\": \".*\"" "\"${escapedModuleName}\": \"~${moduleVersion}\"" package.json
        if [[ `isMacOS` ]]; then
            sed -i '' "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
        else
            sed -i "s/\"${escapedModuleName}\": \".*\"/\"${escapedModuleName}\": \"~${moduleVersion}\"/g" package.json
        fi
        throwError "Error updating version of dependency in package.json"
    done
}

# for now this is duplicate for the sake of fast dev... need to combine the above and this one
function linkThunderstormImpl() {
    local module=${1}
    local BACKTO=`pwd`

    [[ ! "${internalThunderstormRefs}" ]] && internalThunderstormRefs=(${thunderstormLibraries[@]})

    local temp=(${modules[@]})
    modules=(${internalThunderstormRefs[@]})
    cd "${ThunderstormHome}"
        mapModulesVersions
    cd "${BACKTO}"
    modules=(${temp[@]})

    local i
    for (( i=0; i<${#internalThunderstormRefs[@]}; i+=1 )); do
        if [[ "${module}" == "${internalThunderstormRefs[${i}]}" ]]; then break; fi

        [[ `contains "${internalThunderstormRefs[${i}]}" "${projectModules[@]}"` ]] && break;

        local modulePackageName="${modulesPackageName[${i}]}"
        [[ ! "`cat package.json | grep ${modulePackageName}`" ]] && continue;

        logInfo "Linking ${internalThunderstormRefs[${i}]} (${modulePackageName}) => ${module}"
        local target="`pwd`/node_modules/${modulePackageName}"
        local origin="${ThunderstormHome}/${internalThunderstormRefs[${i}]}/dist"

        createDir ${target}

        chmod -R 777 ${target}
        deleteDir ${target}

        logDebug "ln -s ${origin} ${target}"
        ln -s ${origin} ${target}
        throwError "Error symlink dependency: ${modulePackageName}"
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
            deleteDir node_modules/@nu-art
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

function cloneThunderstormModules() {
    local module
    for module in "${thunderstormLibraries[@]}"; do
        logDebug " * Cloning Submodule : ${module}"
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
    for module in "${thunderstormLibraries[@]}"; do
        if [[ ! -e "${module}" ]]; then
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        fi
    done

    for module in "${thunderstormLibraries[@]}"; do
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

    for module in "${thunderstormLibraries[@]}"; do
        if [[ ! -e "${module}" ]]; then
            throwError "In order to promote a version ALL nu-art dependencies MUST be present!!!" 2
        fi

        cd ${module}
            gitAssertBranch master
            gitAssertRepoClean
            gitFetchRepo
            gitAssertNoCommitsToPull

            if [[ `gitAssertTagExists ${nuArtVersion}` ]]; then
                throwError "Tag already exists: v${nuArtVersion}" 2
            fi
        cd ..
    done

    logInfo "Repo is ready for version promotion"
    logInfo "Promoting Libs: ${versionName} => ${nuArtVersion}"
    setVersionName ${nuArtVersion} ${versionFile}
    executeOnModules linkSourcesImpl

    for module in "${thunderstormLibraries[@]}"; do
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
    if [[ ! "${newAppVersion}" ]]; then
        throwError "MUST specify a new version for the apps... use --set-version=x.y.z" 2
    fi

    appVersion=${newAppVersion}
    logInfo "Asserting repo readiness to promote a version..."
    if [[ `gitAssertTagExists ${appVersion}` ]]; then
        throwError "Tag already exists: v${appVersion}" 2
    fi

    gitAssertBranch "${allowedBranchesForPromotion[@]}"
    gitFetchRepo
    gitAssertNoCommitsToPull

    local versionFile="version-app.json"
    local versionName=`getVersionName ${versionFile}`
    logInfo "Promoting Apps: ${versionName} => ${appVersion}"
    setVersionName ${appVersion} ${versionFile}
    executeOnModules linkSourcesImpl

    local currentBranch=`gitGetCurrentBranch`

    gitTag "v${appVersion}" "Promoted apps to: v${appVersion}"
    gitPushTags
    throwError "Error pushing promotion tag"
}

function publishNuArt() {
    for module in "${thunderstormLibraries[@]}"; do
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


function setEnvironment() {
    logInfo "Setting envType: ${envType}"
    [[ "${fallbackEnv}" ]] && logWarning " -- Fallback env: ${fallbackEnv}"

    copyConfigFile "./.config/firebase-ENV_TYPE.json" "firebase.json" ${envType} ${fallbackEnv}
    copyConfigFile "./.config/.firebaserc-ENV_TYPE" ".firebaserc" ${envType} ${fallbackEnv}
    if [[ -e ${backendModule} ]]; then
        cd ${backendModule}
            copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" ${envType} ${fallbackEnv}
        cd - > /dev/null
    fi

    if [[ -e ${frontendModule} ]]; then
        cd ${frontendModule}
            copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" ${envType} ${fallbackEnv}
        cd - > /dev/null
    fi

    firebase use `getJsonValueForKey .firebaserc "default"`
}

function copyConfigFile() {
    local filePattern=${1}
    local targetFile=${2}

    local envs=(${@:4})

    for env in ${envs[@]}; do
        local envConfigFile=${filePattern//ENV_TYPE/${env}}
        [[ ! -e "${envConfigFile}" ]] && continue

        logInfo "Setting ${targetFile} from env: ${env}"
        cp "${envConfigFile}" ${targetFile}
        return 0
    done

    throwError "Could not find a match for target file: ${targetFile} in envs: ${envs[@]}" 2
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

if [[ "${printEnv}" ]]; then
    assertNodePackageInstalled typescript
    assertNodePackageInstalled tslint
    assertNodePackageInstalled firebase-tools
    assertNodePackageInstalled sort-package-json
    logDebug "node version: "`node -v`
    logDebug "npm version: "`npm -v`
    logDebug "bash version: "`getBashVersion`
    exit 0
fi

if [[ "${#modules[@]}" == 0 ]]; then
    if [[ "${buildThunderstorm}" ]]; then
        modules+=(${thunderstormLibraries[@]})
    fi
    modules+=(${dependencyModules[@]})
    modules+=(${projectModules[@]})
fi

if [[ "${mergeOriginRepo}" ]]; then
    bannerInfo "Merge Origin"
    mergeFromFork
    logInfo "Merged from origin boilerplate... DONE"
    exit 0
fi

if [[ "${cloneThunderstorm}" ]]; then
    bannerInfo "Cloning Thunderstorm sources"
    cloneThunderstormModules
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
    assertNodePackageInstalled typescript
    assertNodePackageInstalled firebase-tools
    assertNodePackageInstalled sort-package-json
    assertNodePackageInstalled nodemon
    assertNodePackageInstalled tslint

    bannerInfo "setup"
    executeOnModules setupModule
fi

if [[ "${linkDependencies}" ]]; then
    bannerInfo "link dependencies"
    if [[ "${ThunderstormHome}" ]] && [[ "${linkThunderstorm}" ]]; then
        executeOnModules linkThunderstormImpl
    else
        executeOnModules linkDependenciesImpl
    fi

    mapModulesVersions
    printVersions
fi


if [[ "${build}" ]]; then
    executeOnModules linkSourcesImpl
    executeOnModules buildModule
fi

if [[ "${lint}" ]]; then
    bannerInfo "lint"
    executeOnModules lintModule
fi

if [[ "${testModules}" ]]; then
    bannerInfo "test"
    executeOnModules testModule
fi

# PRE-Launch and deploy

if [[ "${newAppVersion}" ]]; then
    bannerInfo "promote apps"
    promoteApps
fi

# LAUNCH
if [[ "${runBackendTests}" ]]; then
    cd ${backendModule}
        npm run test
    cd ..
    exit 0
fi

if [[ "${launchBackend}" ]]; then
    bannerInfo "launchBackend"
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

    if [[ "${deployBackend}" ]] && [[ -e ${backendModule} ]]; then
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only functions
        throwWarning "Error while deploying functions"
    fi

    if [[ "${deployFrontend}" ]] && [[ -e ${frontendModule} ]];  then
        logInfo "Using firebase project: ${firebaseProject}"
        firebase use ${firebaseProject}
        firebase deploy --only hosting
        throwWarning "Error while deploying hosting"
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