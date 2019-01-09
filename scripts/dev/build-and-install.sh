#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash

source ${BASH_SOURCE%/*}/../_core-tools/_source.sh
enforceBashVersion 4.4

apkPattern="*.apk"
deviceIdParam=""
errorFileName=error

paramColor=${BBlue}
valueColor=${BGreen}

function printUsage {
    local errorMessage=${1}

    local packageNameParam="${paramColor}--packageName=${NoColor}"
    if [[ ! "${packageName}" ]]; then
        packageNameParam="${packageNameParam}${valueColor}your.package.name.here${NoColor}"
    else
        packageNameParam="${packageNameParam}${valueColor}${packageName}${NoColor}"
    fi

    local projectParam="${paramColor}--project=${NoColor}"
    if [[ ! "${projectName}" ]]; then
        projectParam="${projectParam}${valueColor}you-project-name${NoColor}"
    else
        projectParam="${projectParam}${valueColor}${projectName}${NoColor}"
    fi

    local buildParam="${paramColor}--build=${NoColor}${buildParam}${valueColor}build-type${NoColor}"
    local deviceIdParam="${paramColor}--device-id=${NoColor}${valueColor}your-device-id-here${NoColor} | ${valueColor}ALL${NoColor}"
    local uninstallParam="${paramColor}optional flags:${NoColor} ${valueColor}--uninstall${NoColor} | ${valueColor}--offline${NoColor} | ${valueColor}--no-build${NoColor} | ${valueColor}--clear-cache${NoColor}"

    logVerbose
    if [[ "${errorMessage}" ]]; then
        logError "    ${errorMessage}"
        logVerbose
    fi
    logVerbose "   USAGE:"
    logVerbose "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor}"
    logVerbose
    logVerbose "               MUST:"
    logVerbose "                         ${packageNameParam}"
    logVerbose "                         ${projectParam}"
    logVerbose "                         ${buildParam}"
    logVerbose "                               |-- or use the --no-build flag"
    logVerbose
    logVerbose "           OPTIONAL:"
    logVerbose "                         ${deviceIdParam}"
    logVerbose "                         ${uninstallParam}"
    logVerbose
    exit
}

if [[ ! "${ANDROID_HOME}" ]]; then
    ANDROID_HOME="/Users/$USER/Library/Android/sdk"
fi

adbCommand=${ANDROID_HOME}/platform-tools/adb

offline=""
nobuild=""
deviceIds=("")
outputFolder=
packageName=

function waitForDevice() {
    local deviceId=${1}
    local message=${2}

    device=`adb devices | grep ${deviceId}`

    if [[ ! "${device}" ]]; then
        logError "Error waiting for device... no deviceId specified!!"
        exit 2
    fi
    
    if [[ ! "${message}" ]]; then
        message="Waiting for device"
    fi

    logWarning "${message}..."
    sleep 5s
    waitForDevice ${1} "${2}"
}
function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--package-name="*)
                packageName=`echo "${paramValue}" | sed -E "s/--package-name=(.*)/\1/"`
            ;;

            "--path-to-apk="*)
                pathToApk=`echo "${paramValue}" | sed -E "s/--path-to-apk=(.*)/\1/"`
            ;;

            "--path-to-test-apk="*)
                pathToTestApk=`echo "${paramValue}" | sed -E "s/--path-to-test-apk=(.*)/\1/"`
            ;;

            "--apk-pattern="*)
                apkPattern=`echo "${paramValue}" | sed -E "s/--apk-pattern=(.*)/\1/"`
            ;;

            "--app-name="*)
                appName=`echo "${paramValue}" | sed -E "s/--app-name=(.*)/\1/"`
            ;;

            "--device-id="*)
                deviceIdParam=`echo "${paramValue}" | sed -E "s/--device-id=(.*)/\1/"`
            ;;

            "--project="*)
                projectName=`echo "${paramValue}" | sed -E "s/--project=(.*)/\1/"`
            ;;

            "--folder="*)
                projectFolder=`echo "${paramValue}" | sed -E "s/--folder=(.*)/\1/"`
            ;;

            "--build="*)
                buildType=`echo "${paramValue}" | sed -E "s/--build=(.*)/\1/"`
            ;;

            "--tests-to-run="*)
                testsToRun=`echo "${paramValue}" | sed -E "s/--tests-to-run=(.*)/\1/"`
            ;;

            "--clean"*)
                clean=" clean"
            ;;

            "--debug"*)
                debug="true"
            ;;

            "--clear-data")
                clearData="true"
            ;;

            "--delete-apks")
                deleteApks="true"
            ;;

            "--uninstall")
                uninstall="true"
                clearData=
                forceStop=
            ;;

            "--uninstall-only")
                clearData=
                forceStop=
                noInstall="true"
                noBuild="true"
                noLaunch="true"
                uninstall="true"
            ;;

            "--force-stop")
                forceStop="true"
            ;;

            "--offline")
                offline=" --offline"
            ;;

            "--no-build")
                noBuild="true"
            ;;

            "--no-install")
                noInstall="true"
            ;;

            "--test-mode")
                testMode="true"
                testFlag="-t "
            ;;

            "--no-launch")
                noLaunch="true"
            ;;

            "--wait-for-device")
                waitForDevice="true"
            ;;

            "--only-build")
                noLaunch="true"
                noInstall="true"
            ;;

            "*")
                echo "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}

signature
printCommand "$@"
extractParams "$@"

function verifyHasDevices() {
    local message=${1}

    if [[ "${#deviceIds[@]}" == "0" ]]; then
        logError "${message}"
        logError "No device found"
        exit 1
    fi
}

if [[ ! "${projectFolder}" ]]; then
    projectFolder="${projectName}"
fi

if [[ ! "${appName}" ]]; then
    appName="${packageName}"
fi

outputFolder="${projectFolder}/build/outputs/apk/${buildType}"
if [[ "${testMode}" ]]; then
    outputTestFolder="${projectFolder}/build/outputs/apk/androidTest/${buildType}"
fi


params=(appName packageName buildType projectName projectFolder outputFolder pathToApk outputTestFolder pathToTestApk apkPattern deviceIdParam testMode uninstall clearData forceStop clean build noBuild noInstall noLaunch waitForDevice)
printDebugParams ${debug} "${params[@]}"

if [[ ! "${packageName}" ]]; then
    printUsage "No package name defined"
fi

if [[ ! -d "${projectFolder}" ]]; then
    printUsage "No project folder for path: '${projectFolder}'"
fi

if [[ ! "${buildType}" ]] && [[ ! "${noBuild}" ]] && [[ ! "${uninstall}" ]] && [[ ! "${clearData}" ]] && [[ ! "${deleteApks}" ]]; then
    printUsage "MUST specify build type or set flag --no-build"
fi

function resolveDeviceId() {
    if [[ ! "${deviceIdParam}" ]] || [[ "${deviceIdParam}" == "ALL" ]] || [[ "${deviceIdParam}" == "all" ]]; then
        deviceIds=(`adb devices | grep -E "^[0-9a-zA-Z\-]+\s+?device$" | sed -E "s/([0-9a-zA-Z-]+).*/\1/"`)
        if [[ ! "${deviceIdParam}" ]] && (("${#deviceIds[@]}" > "1")); then

            deviceIdParam=`choicePrintOptions "More than one device connected, please specify which device: " "ALL" ${deviceIds[@]}`
            resolveDeviceId
        fi
    else
        deviceIds=(`echo "${deviceIdParam}"`)
    fi
}

###################################################################
#                                                                 #
#                          EXECUTION                              #
#                                                                 #
###################################################################


function yesOrNoQuestion() {
    local message=${1}
    local toExecuteYes="${2}"
    local toExecuteNo=${3}

    echo
    logWarning "${message}"
    read  -n 1 -p "" response

    case "$response" in
        [yY])
                execute "${toExecuteYes}"
             ;;
        [nN])
                execute "${toExecuteNo}"
            ;;
        *)
                echo
                logError "Canceling..."
                exit 2
            ;;
    esac
}

function waitForDeviceImpl() {
    if [[ ! "${waitForDevice}" ]]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
       waitForDevice ${deviceId}
    done
}

function uninstallFromDevice() {
    local deviceId=${1}
    waitForDevice ${deviceId}
    execute "${adbCommand} -s ${deviceId} uninstall ${packageName}" "Uninstalling '${appName}':"
}

function uninstallImpl() {
    if [[ ! "${uninstall}" ]]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
        uninstallFromDevice "${deviceId}"
    done
}

function buildImpl() {
    if [[ "${noBuild}" ]]; then
          return
    fi

    execute "rm -rf ${outputFolder}" "deleting output folder:"
    local command="${command} ${projectName}:assemble${buildType}"
    if [[ "${testMode}" ]]; then
        command="${command} ${projectName}:assemble${buildType}AndroidTest"
    fi

    execute "bash gradlew${clean}${command}${offline}" "Building '${appName}'..."
    checkExecutionError "Build error..."
}

function deleteApksImpl() {
    if [[ "${deleteApks}" ]]; then
        execute "rm -rf ${outputFolder}" "deleting output folder:"
    fi
}

function clearDataImpl() {
    if [[ ! "${clearData}" ]]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} shell pm clear ${packageName}" "Clearing data for '${appName}':"
    done
}

function forceStopImpl() {
    if [[ ! "${forceStop}" ]]; then
        return
    fi

    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} shell am force-stop ${packageName}" "Force stopping Remote-Screen app..."
    done
}

function retry() {
    local output=${1}
    local installCommand=${2}
    local uninstallCommand=${3}
    local errorMessage=${4}

    logVerbose ${output}

    if [[ "${output}" =~ "INSTALL_FAILED_UPDATE_INCOMPATIBLE" ]]; then
        yesOrNoQuestion "Apk Certificate changed, do you want to uninstall previous version? [y(yes)/n(bo)/c(cancel)]" "${uninstallCommand}; ${installCommand}" "logError \"${errorMessage}\""
        return
    fi

    if [[ "${output}" =~ "INSTALL_PARSE_FAILED_NO_CERTIFICATES" ]]; then
        installCommand
        return
    fi

    if [[ "${output}" =~ "INSTALL_FAILED_VERSION_DOWNGRADE" ]]; then
        yesOrNoQuestion "Failed to install! trying to install an older version, Uninstall newer version? [y/n]" "${uninstallCommand}; ${installCommand}" "logError \"${errorMessage}\"; exit 1"
        return
    fi

    if [[ "${output}" =~ "failed to install" ]]; then
        yesOrNoQuestion "Failed to install, Try again? [y/n]" "${installCommand}" "logError \"${errorMessage}\"; exit 1"
        return
    fi
}



function installImpl() {
    function installAppOnDevice() {
        local deviceId=${1}
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} install -r -d ${testFlag}${pathToApk}" "Installing '${appName}':" false 2> ${errorFileName}
        output=`cat ${errorFileName}`
        rm ${errorFileName}

        retry "${output}" "installAppOnDevice \"${deviceId}\"" "uninstallFromDevice \"${deviceId}\"" "COULD NOT INSTALL APP"
    }

    if [[ "${noInstall}" ]]; then
        return
    fi

    if [[ ! -e "${outputFolder}" ]]; then
        logError "Output folder does not exists... Build needed - ${outputFolder}"
        exit 2
    fi

    if [[ ! "${pathToApk}" ]]; then
        pathToApk=`find "${outputFolder}" -name "${apkPattern}"`
    fi

    if [[ ! "${pathToApk}" ]]; then
        logError "Could not find apk in path '${outputFolder}', matching the pattern '${apkPattern}'"
        exit 2
    fi

    verifyHasDevices "Cannot install apk..."
    for deviceId in "${deviceIds[@]}"; do
        installAppOnDevice "${deviceId}"
    done
}

function installTestImpl() {
    function installTestAppOnDevice() {
        local deviceId=${1}
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} install -r -d ${testFlag}${pathToTestApk}" "Installing '${appName}' tests:" false 2> ${errorFileName}
        output=`cat ${errorFileName}`
        rm ${errorFileName}

        retry "${output}" "installAppOnDevice \"${deviceId}\"" "uninstallFromDevice \"${deviceId}\"" "COULD NOT INSTALL APP"
    }


    if [[ ! "${testMode}" ]]; then
        return
    fi

    if [[ "${noInstall}" ]]; then
        return
    fi

    if [[ ! -e "${outputTestFolder}" ]]; then
        logError "Test Output folder does not exists... Build needed - ${outputTestFolder}"
        exit 2
    fi

    if [[ ! "${pathToTestApk}" ]]; then
        pathToTestApk=`find "${outputTestFolder}" -name "${apkPattern}"`
    fi

    if [[ ! "${pathToApk}" ]]; then
        logError "Could not find apk in path '${outputTestFolder}', matching the pattern '${apkPattern}'"
        exit 2
    fi

    verifyHasDevices "Cannot install apk..."
    for deviceId in "${deviceIds[@]}"; do
        installTestAppOnDevice "${deviceId}"
    done
}

function launchImpl() {
    if [[ "${noLaunch}" ]]; then
        return
    fi

    verifyHasDevices "Cannot launch app..."
    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} shell am start -n ${packageName}/com.nu.art.cyborg.ui.ApplicationLauncher -a android.intent.action.MAIN -c android.intent.category.LAUNCHER" "Launching '${appName}':"
    done
}

function runTestsImpl() {
    if [[ ! "${testMode}" ]]; then
        return
    fi

    if [[ ! "${testsToRun}" ]]; then
        return
    fi

    verifyHasDevices "Cannot run tests app..."
    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} shell am instrument -w -r -e debug false -e ${testsToRun} ${packageName}.test/android.support.test.runner.AndroidJUnitRunner" "Running test '${appName}':"
    done
}

deleteApksImpl
forceStopImpl
clearDataImpl
uninstallImpl
buildImpl
installImpl
installTestImpl
launchImpl
runTestsImpl


# For reference

#forceStopImpl
#clearDataImpl
#uninstallImpl
#buildImpl
#installImpl
#launchImpl
