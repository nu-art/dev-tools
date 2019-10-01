#!/bin/bash
source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/ci/typescript/_source.sh

const_BoilerplateFirebaseProject=nu-art-thunderstorm
const_BoilerplateLocation=us-central1
const_LogFolder="`pwd`/.fork"
const_Timestamp=`date +%Y-%m-%d--%H-%M-%S`

repoUrl=git@github.com:nu-art-js/thunderclone.git
localPath=../thunderstorm-forked
withSources=n
allGood=n
firebaseProject=`firebase use | head -1`
firebaseProjectLocation=us-central1

function signatureThunderstorm() {
    clear
    logVerbose "${Gray}             _____ _                     _                    _                                      ${NoColor}"
    logVerbose "${Gray} -------    |_   _| |__  _   _ _ __   __| | ___ _ __      ___| |_ ___  _ __ _ __ ___    ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | '_ \| | | | '_ \ / _\` |/ _ \ '__|____/ __| __/ _ \| '__| '_ \` _ \   ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | | | | |_| | | | | (_| |  __/ | |_____\__ \ || (_) | |  | | | | | |  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      |_| |_| |_|\__,_|_| |_|\__,_|\___|_|       |___/\__\___/|_|  |_| |_| |_|  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------                                                                                ${Gray}   ------- ${NoColor}"
    logVerbose
}
function signatureThunderstorm() {
    clear
    logVerbose "${Gray}             _____ _                     _                    _                                      ${NoColor}"
    logVerbose "${Gray} -------    |_   _| |__  _   _ _ __   __| | ___ _ __      ___| |_ ___  _ __ _ __ ___    ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | '_ \| | | | '_ \ / _\` |/ _ \ '__|____/ __| __/ _ \| '__| '_ \` _ \ ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | | | | |_| | | | | (_| |  __/ | |_____\__ \ || (_) | |  | | | | | |  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      |_| |_| |_|\__,_|_| |_|\__,_|\___|_|       |___/\__\___/|_|  |_| |_| |_|  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------                                                                                ${Gray}   ------- ${NoColor}"
    logVerbose
}

function promptUserForInput() {
    local var=${1}
    local message=${2}
    local defaultValue=${3}

    if [[ "${defaultValue}" ]]; then
        logInfo "${message} [OR press enter to use the current value]"
        logInfo "    (current=${defaultValue})"
    else
        logInfo "${message}"
    fi

    read ${var}
    deleteTerminalLine

    if [[ ! "${!var}" ]]; then
        eval "${var}='${defaultValue}'"
    fi
}

function verifyRepoExists() {
    local repoUrl=${1}

    logDebug "Verifying access to repo ${repoUrl}"
    local output=$(git ls-remote ${repoUrl} 2>&1)
    if [[ "${output}" =~ "Please make sure you have the correct access rights" ]]; then
        return 2
    fi

    if [[ "${output}" =~ "ERROR: Repository not found" ]]; then
        return 1
    fi

    return 0
}

function promptForRepoUrl() {
    promptUserForInput repoUrl "Please enter the repo url to fork into:" ${repoUrl}
    verifyRepoExists ${repoUrl}

    local status=$?
    if [[ "${status}" == "2" ]]; then
        repoUrl=
    fi

    if [[ "${status}" != "0" ]]; then
        deleteTerminalLine 2
        promptForRepoUrl
    fi
    logInfo
}

function verifyNpmPackageInstalledGlobally() {
    local package=${1}
    local version=${2}

    logDebug "Verifying package installed ${package}@${version}..."
    local output=$(npm list -g ${package} | grep ${package} 2>&1)
    local code=$?

    if [[ "${code}" != "0" ]]; then
        return 1
    fi

    local foundVersion=`echo ${output} | tail -1 | sed -E "s/.*${package}@(.*)/\1/"`
    if [[ "${foundVersion}" != "${version}" ]]; then
        logWarning "Found wrong version '${foundVersion}' of '${package}...'"
        logInfo "Installing required package version: ${package}@${version}"
        npm i -g ${package}@${version}
        return 1
    fi

    return 0
}

function verifyFirebaseProjectIsAccessible() {
    local firebaseProject=${1}

    logDebug "Verifying You are logged in to firebase tools...'"
    firebase login
    logDebug

    logDebug "Verifying access to firebase project: '${firebaseProject}'"
    local output=$(firebase list | grep "${firebaseProject}" 2>&1)
    if [[ "${output}" =~ "Command requires authentication" ]]; then
        logError "    User not logged in"
        return 2
    fi

    if [[ ! "${output}" =~ "${firebaseProject}" ]]; then
        logError "    No access found"
        return 1
    fi
    return 0
}

function promptForFirebaseProject() {
    promptUserForInput firebaseProject "Please enter the Firebase Project you will be using:" ${firebaseProject}
    logInfo

    verifyFirebaseProjectIsAccessible ${firebaseProject}
    local status=$?
    if [[ "${status}" == "2" ]]; then
        logWarning "Please open another terminal and run 'firebase login' and follow the instruction... \nOnce logged in return to this terminal press enter"
        promptForFirebaseProject
        return
    fi

    if [[ "${status}" != "0" ]]; then
        logWarning "Make sure you have access rights to the firebase project called: ${firebaseProject}"
        promptForFirebaseProject
        return
    fi

    logInfo
}

function promptForFirebaseProjectLocationRepo() {
    promptUserForInput projectLocation "Please enter the Firebase Project LOCATION assigned to your project" ${firebaseProjectLocation}
    logInfo
}

function installNpmPackages() {
    logInfo "Verify required npm packages are installed"
    verifyNpmPackageInstalledGlobally "typescript" 3.6.3
    verifyNpmPackageInstalledGlobally "tslint" 5.20.0
    verifyNpmPackageInstalledGlobally "firebase-tools" 7.4.0
    verifyNpmPackageInstalledGlobally "nodemon" 1.19.3
    verifyNpmPackageInstalledGlobally "sort-package-json" 1.22.1
    logInfo
}

#function verifyLocalPathExists() {
#    local localPath=${1}
#    if [[ -d "${localPath}" ]]; then
#        return 0
#    fi
#
#    mkdir ${localPath}
#    return $?
#}

function promptForLocalPathForFork() {
    promptUserForInput localPath "Please enter the path to fork the project to:" ${localPath}
    local deleteLocalFolder=y
    if [[ -e "${localPath}" ]]; then
        yesOrNoQuestion_new deleteLocalFolder "Folder already exists and need to be deleted: ${localPath}\n Delete Folder? [Y/n]" ${deleteLocalFolder}
        case "${deleteLocalFolder}" in
            [y])
                deleteFolder ${localPath}
            ;;

            [n])
                promptForLocalPathForFork
                return
            ;;
        esac

    fi
    logInfo
}

function promptForWithOrWithoutSources() {
    yesOrNoQuestion_new withSources "Do you want to fork with the thunderstorm sources: [y/N]" ${withSources}
}

function promptUserForConfirmation() {
    local userInput=""
    userInput="${userInput}\n    Git fork repository url: ${repoUrl}"
    userInput="${userInput}\n    Local folder for project: ${localPath}"
    userInput="${userInput}\n    Your firebase project name: ${firebaseProject}"
    userInput="${userInput}\n    Your firebase project location: ${firebaseProjectLocation}"
    userInput="${userInput}\n    Keep Thunderstorm sources: ${withSources}"

    yesOrNoQuestion_new allGood "Are all these details correct: [y/N]\n${userInput}" ${allGood}

    case "${allGood}" in
        [n])
            logError "Aborting fork due to incorrect user input!!"
            exit 2
        ;;
    esac

}

function uploadDefaultConfigToFirebase() {
    logInfo "Setting boilerplate example config to your project"
    local backupFile="${const_LogFolder}/${firebaseProject}_backup_${const_Timestamp}.json"

    logWarning "If your database has content it will be backed up to: ${backupFile}"
    firebase database:get / > ${backupFile}

    logDebug "Setting example config..."
    firebase database:set -y / .stuff/initial-config.json
}

function forkThunderstorm() {
    local forkingOutput="${const_LogFolder}/${firebaseProject}_forking_${const_Timestamp}.json"
    logInfo "Forking Thunderstorm boilerplate into...  ${repoUrl}"
    bash ./dev-tools/scripts/git/git-fork.sh --to=${repoUrl} --output=${localPath} > ${forkingOutput}
    throwError "Error while forking Thunderstorm... logs can be found here: ${forkingOutput}"
}

function cleanUpForkedRepo() {
    deleteFile ./version-nu-art.json
    if [[ "${withSources}" == "n" ]]; then
        deleteFolder ./ts-common
        deleteFolder ./testelot
        deleteFolder ./thunder
        deleteFolder ./storm
    fi
}

function replaceBoilerplateNamesWithNewForkedNames() {
    renameStringInFiles ./ ${const_BoilerplateFirebaseProject} "${firebaseProject}" "dev-tools"
    renameStringInFiles ./ ${const_BoilerplateLocation} "${firebaseProjectLocation}" "dev-tools"
}

function prepareForkedProjectEnvironment() {
    local output="${const_LogFolder}/${firebaseProject}_prepare_${const_Timestamp}.json"
    logInfo "Preparing project env..."
    bash build-and-install.sh -se=dev -nb > ${output}
    throwError "Error while Preparing forked Thunderstorm... logs can be found here: ${output}"
}

function pushPreparedProjectToRepo() {
    gitCommit "Forked project is prepared!"
    gitPush
}

function setupForkedProject() {
    local output="${const_LogFolder}/${firebaseProject}_setup_${const_Timestamp}.json"
    logInfo "Running initial setup of forked repo..."
    bash build-and-install.sh -se=dev --setup > ${output}
    throwError "Error while setting up forked Thunderstorm... logs can be found here: ${output}"
}

function launchForkedProject() {
    local output="${const_LogFolder}/${firebaseProject}_launch_${const_Timestamp}.json"
    logInfo "Launching forked project..."
    bash ./build-and-install.sh -lf -lb> ${output}
    throwError "Error while launching forked Thunderstorm... logs can be found here: ${output}"
}

function promptUserToLaunchDeployOrExit() {
    logInfo "To LAUNCH your forked project run: bash build-and-install.sh -lf -lb"
    logInfo "To DEPLOY your forked project run: bash build-and-install.sh -se=staging -df -db"
}

function sayHello() {
    signatureThunderstorm
    logInfo "Let's fork thunderstorm...."
    logInfo
    sleep 2s

    logWarning "If you are not familiar with Firebase or git... please educate yourself!"
    logWarning "Bellow is a link to a video tutorial on how to fork Thunderstorm:"
    logWarning
    logWarning "   https://future-link-here"
    logWarning
    sleep 5s
}

function start() {
    sayHello

    installNpmPackages
    promptForRepoUrl
    promptForFirebaseProject
    promptForFirebaseProjectLocationRepo
    promptForLocalPathForFork
    promptForWithOrWithoutSources

    promptUserForConfirmation

    forkThunderstorm
    cd ${localPath}
        cleanUpForkedRepo
        replaceBoilerplateNamesWithNewForkedNames
        prepareForkedProjectEnvironment
        pushPreparedProjectToRepo
        uploadDefaultConfigToFirebase
        setupForkedProject
        promptUserToLaunchDeployOrExit

    sayGoodbye
#    echo "Your forked repo url: ${repoUrl}"
#    echo "Your Firebase project: ${firebaseProject}"
#    echo "The Firebase project location: ${firebaseProjectLocation}"
}

start