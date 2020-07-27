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

source ${BASH_SOURCE%/*}/../../android/_source.sh
enforceBashVersion 4.4
setDefaultAndroidHome

paramColor=${BBlue}
valueColor=${BGreen}

printUsage() {
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

adbCommand=${ANDROID_HOME}/platform-tools/adb
launcherClass=com.nu.art.cyborg.ui.ApplicationLauncher
trashFolder="./.trash"
deviceIds=("")
apkPattern="*.apk"
errorFileName=error.tmp

deviceIdParam=
printDependencies=
offline=
nobuild=
outputFolder=
packageName=
projectName=
pathToApk=
pathToTestApk=
appName=
projectFolder=
buildType=
flavor=
javaTests=
outputTestFolder=

params=(appName packageName launcherClass buildType flavor projectName projectFolder printDependencies outputFolder pathToApk outputTestFolder javaTests pathToTestApk apkPattern deviceIdParam testMode uninstall clearData forceStop clean build noBuild noInstall noLaunch waitForDevice)

extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--launcher-class="*)
                launcherClass=`regexParam "--launcher-class" "${paramValue}"`
            ;;

            "--package-name="*)
                packageName=`regexParam "--package-name" "${paramValue}"`
            ;;

            "--path-to-apk="*)
            ;;

            "--path-to-test-apk="*)
                pathToTestApk=`regexParam "--path-to-test-apk" "${paramValue}"`
            ;;

            "--apk-pattern="*)
                apkPattern=`regexParam "--apk-pattern" "${paramValue}"`
            ;;

            "--app-name="*)
                appName=`regexParam "--app-name" "${paramValue}"`
            ;;

            "--device-id="*)
                deviceIdParam=`regexParam "--device-id" "${paramValue}"`
            ;;

            "--project="*)
                projectName=`regexParam "--project" "${paramValue}"`
            ;;

            "--folder="*)
                projectFolder=`regexParam "--folder" "${paramValue}"`
            ;;

            "--build="*)
                buildType=`regexParam "--build" "${paramValue}"`
            ;;

            "--flavor="*)
                flavor=`regexParam "--flavor" "${paramValue}"`
            ;;

            "--tests-to-run="*)
                testsToRun=`regexParam "--tests-to-run" "${paramValue}"`
            ;;

            "--test")
                javaTests=true
            ;;

            "--clean")
                clean=" clean"
            ;;

            "--debug")
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

            "--dependencies" | "--tree")
                printDependencies="true"
                noBuild=true
                noInstall=true
                noLaunch=true
            ;;

            "*")
                logWarning "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}

signature
printCommand "$@"
extractParams "$@"

verifyHasDevices() {
    local message=${1}

    if [[ "${#deviceIds[@]}" == "0" ]]; then
        logError "${message}"
        throwError "${message}\nNo device found" 2
    fi
}

if [[ ! "${projectFolder}" ]]; then
    projectFolder="${projectName}"
fi

if [[ ! "${appName}" ]]; then
    appName="${packageName}"
fi

outputFolder="${projectFolder}/build/outputs/apk/${flavor}/${buildType}"
if [[ "${testMode}" ]]; then
    outputTestFolder="${projectFolder}/build/outputs/apk/androidTest/${buildType}"
fi


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

DeviceRegexp_UsbDevice="[0-9a-zA-Z\-]+"
DeviceRegexp_NetworkDevice="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:[0-9]{2,5}"


resolveDeviceId() {
    if [[ ! "${deviceIdParam}" ]] || [[ "${deviceIdParam}" == "ALL" ]] || [[ "${deviceIdParam}" == "all" ]]; then
        deviceIds=(`adb devices | grep -E "^${DeviceRegexp_UsbDevice}\s+?device$" | sed -E "s/(${DeviceRegexp_UsbDevice}).*/\1/"`)
        local networkDevices=(`adb devices | grep -E "^${DeviceRegexp_NetworkDevice}.*$"  | sed -E "s/(${DeviceRegexp_NetworkDevice}).*/\1/"`)
        deviceIds+=${networkDevices[@]}

        if [[ ! "${deviceIdParam}" ]] && (("${#deviceIds[@]}" > "1")); then
            choicePrintOptions "No device was specified, please select one: " "ALL" ${deviceIds[@]}
            deviceIdParam=`choiceWaitForInput "ALL" ${deviceIds[@]}`
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

runOnAllDevices() {
    local toExecute=${1}
    resolveDeviceId
    verifyHasDevices "Cannot call ${toExecute} without any device"
    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId}
        ${toExecute} "${deviceId}"
    done
}

uninstallFromDevice() {
    local deviceId=${1}
    execute "${adbCommand} -s ${deviceId} uninstall ${packageName}" "Uninstalling '${appName}':"
}

uninstallImpl() {
    if [[ ! "${uninstall}" ]]; then
          return
    fi

    runOnAllDevices "uninstallFromDevice"
}


buildImpl() {
    if [[ "${noBuild}" ]]; then
          return
    fi

    execute "rm -rf ${outputFolder}" "deleting output folder:"
    local command="${command} ${projectName}:assemble${buildType}"
    if [[ "${testMode}" ]]; then
        command="${command} ${projectName}:assemble${buildType}AndroidTest"
    fi

    execute "bash gradlew${clean}${command}${offline} " "Building '${appName}'..."
    throwError "Build error..."
}

javaTestsImpl() {
    if [[ "${javaTests}" ]]; then
        execute "bash gradlew test -i" "testing '${appName}'..."
        throwError "Test error..."
    fi
}

deleteApksImpl() {
    if [[ "${deleteApks}" ]]; then
        execute "rm -rf ${outputFolder}" "deleting output folder:"
    fi
}

clearDataFromDevice() {
    local deviceId=${1}
    execute "${adbCommand} -s ${deviceId} shell pm clear ${packageName}" "Clearing data for '${appName}':"
}

clearDataImpl() {
    if [[ ! "${clearData}" ]]; then
          return
    fi

    runOnAllDevices "clearDataFromDevice"
}

forceStopOnDevice() {
    local deviceId=${1}
    execute "${adbCommand} -s ${deviceId} shell am force-stop ${packageName}" "Force stopping Remote-Screen app..."
}

forceStopImpl() {
    if [[ ! "${forceStop}" ]]; then
        return
    fi

    runOnAllDevices "forceStopOnDevice"
}

retry() {
    local output=${1}
    local installCommand=${2}
    local uninstallCommand=${3}
    local errorMessage=${4}

    logVerbose ${output}

    if [[ "${output}" =~ "INSTALL_FAILED_UPDATE_INCOMPATIBLE" ]]; then
        yesOrNoQuestion "Apk Certificate changed, do you want to uninstall previous version? [y(yes)/n(bo)/c(cancel)]" "${uninstallCommand} && ${installCommand}" "logError \"${errorMessage}\""
        return
    fi

    if [[ "${output}" =~ "INSTALL_PARSE_FAILED_NO_CERTIFICATES" ]]; then
        installCommand
        return
    fi

    if [[ "${output}" =~ "INSTALL_FAILED_VERSION_DOWNGRADE" ]]; then
        yesOrNoQuestion "Failed to install! trying to install an older version, Uninstall newer version? [y/n]" "${uninstallCommand} && ${installCommand}" "throwError \"${errorMessage}\" 2"
        return
    fi

    if [[ "${output}" =~ "failed to install" ]]; then
        yesOrNoQuestion "Failed to install, Try again? [y/n]" "${installCommand}" "throwError \"${errorMessage}\" 2"
        return
    fi
}



installImpl() {
    installAppOnDevice() {
        local deviceId=${1}
        waitForDevice ${deviceId}
        local targetApkName="${appName}-app.apk"
        local pathToTargetApkName="/data/local/tmp/${targetApkName}"

        logVerbose
        execute "${adbCommand} -s ${deviceId} push ${pathToApk} ${pathToTargetApkName}" "Copy ${appName} apk onto device: ${pathToTargetApkName}" 2> ${errorFileName}
        logVerbose
        execute "${adbCommand} -s ${deviceId} shell pm install -r -d  ${pathToTargetApkName}" "Installing ${appName} apk onto device: ${pathToTargetApkName}" true 2> ${errorFileName}

        output=`cat ${errorFileName}`
        rm ${errorFileName}

        retry "${output}" "installAppOnDevice ${deviceId}" "uninstallFromDevice ${deviceId}" "COULD NOT INSTALL APP"
    }

    if [[ "${noInstall}" ]]; then
        return
    fi

    if [[ ! -e "${outputFolder}" ]]; then
        throwError "Output folder does not exists... Build needed - ${outputFolder}" 2
    fi

    if [[ ! "${pathToApk}" ]]; then
        pathToApk=`find "${outputFolder}" -name "${apkPattern}"`
    fi

    if [[ ! "${pathToApk}" ]]; then
        throwError "Could not find apk in path '${outputFolder}', matching the pattern '${apkPattern}'" 2
    fi

    runOnAllDevices "installAppOnDevice"
}

installTestImpl() {
    installTestAppOnDevice() {
        local deviceId=${1}
        waitForDevice ${deviceId}
        execute "${adbCommand} -s ${deviceId} install -r -d ${testFlag}${pathToTestApk}" "Installing '${appName}' tests:" true 2> ${errorFileName}
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
        throwError "Test Output folder does not exists... Build needed - ${outputTestFolder}" 2
    fi

    if [[ ! "${pathToTestApk}" ]]; then
        pathToTestApk=`find "${outputTestFolder}" -name "${apkPattern}"`
    fi

    if [[ ! "${pathToApk}" ]]; then
        throwError "Could not find apk in path '${outputTestFolder}', matching the pattern '${apkPattern}'" 2
    fi

    runOnAllDevices "installTestAppOnDevice"
}

launchImpl() {
    if [[ "${noLaunch}" ]]; then
        return
    fi

    launchOnDevice() {
        local deviceId=${1}
        execute "${adbCommand} -s ${deviceId} shell am start -n ${packageName}/${launcherClass} -a android.intent.action.MAIN -c android.intent.category.LAUNCHER" "Launching '${appName}':"
    }

    runOnAllDevices "launchOnDevice"
}

runTestsImpl() {
    if [[ ! "${testMode}" ]]; then
        return
    fi

    if [[ ! "${testsToRun}" ]]; then
        return
    fi

    runTestsOnDevice() {
        local deviceId=${1}
        execute "${adbCommand} -s ${deviceId} shell am instrument -w -r -e debug false -e ${testsToRun} ${packageName}.test/android.support.test.runner.AndroidJUnitRunner" "Running test '${appName}':"
    }

    runOnAllDevices "runTestsOnDevice"
}

dependenciesImpl() {
    if [[ ! "${printDependencies}" ]]; then
        return
    fi

    local outputPath="${trashFolder}/tree"
    createDir "${outputPath}"
    local dateTimeFormatted=`date +%Y-%m-%d--%H-%M-%S`

    local outputFile=${outputPath}/${dateTimeFormatted}.txt
    logInfo "printing dependencies into ${outputFile}"
    bash gradlew ${projectName}:dependencies > ${outputFile}
    ERROR_CODE=$?

    exit ${ERROR_CODE}
}

dependenciesImpl
deleteApksImpl
forceStopImpl
clearDataImpl
uninstallImpl
buildImpl
javaTestsImpl
installImpl
installTestImpl
launchImpl
runTestsImpl