#!/bin/bash

bashVersion=`bash --version | grep version | sed -E "s/.* version (.).*/\1/"`
apkPattern="*.apk"
deviceIdParam=""

paramColor=${BBlue}
valueColor=${BGreen}

function printUsage {
    local errorMessage=${1}

    packageNameParam="${paramColor}--packageName=${NoColor}"
    if [ "${packageName}" == "" ]; then
        packageNameParam="${packageNameParam}${valueColor}your.package.name.here${NoColor}"
    else
        packageNameParam="${packageNameParam}${valueColor}${packageName}${NoColor}"
    fi

    projectParam="${paramColor}--project=${NoColor}"
    if [ "${projectName}" == "" ]; then
        projectParam="${projectParam}${valueColor}you-project-name${NoColor}"
    else
        projectParam="${projectParam}${valueColor}${projectName}${NoColor}"
    fi

    buildParam="${paramColor}--build=${NoColor}${buildParam}${valueColor}build-type${NoColor}"
    deviceIdParam="${paramColor}--device-id=${NoColor}${valueColor}your-device-id-here${NoColor} | ${valueColor}ALL${NoColor}"
    uninstallParam="${paramColor}optional flags:${NoColor} ${valueColor}--uninstall${NoColor} | ${valueColor}--offline${NoColor} | ${valueColor}--no-build${NoColor} | ${valueColor}--clear-cache${NoColor}"

    echo
    if [ "${errorMessage}" != "" ]; then
        logError "    ${errorMessage}"
        echo
    fi
    echo -e "   USAGE:"
    echo -e "     ${BBlack}bash${NoColor} ${BCyan}${0}${NoColor}"
    echo
    echo -e "               MUST:"
    echo -e "                         ${packageNameParam}"
    echo -e "                         ${projectParam}"
    echo -e "                         ${buildParam}"
    echo -e "                               |-- or use the --no-build flag"
    echo
    echo -e "           OPTIONAL:"
    echo -e "                         ${deviceIdParam}"
    echo -e "                         ${uninstallParam}"
    echo
    exit
}

if [ "${ANDROID_HOME}" == "" ]; then
    ANDROID_HOME="/Users/$USER/Library/Android/sdk"
fi

adbCommand=${ANDROID_HOME}/platform-tools/adb

offline=""
nobuild=""
deviceIds=("")

function waitForDevice() {
    local deviceId=${1}
    local connected=${2}
    local message=${3}

    device=`adb devices | grep ${deviceId}`

    if [ "${device}" != "" ] && [ "${connected}" == "false" ]; then
        if [ "${message}" == "" ]; then
            message="Disconnect device"
        fi
        logWarning "${message}..."
        sleep 5s
        waitForDevice ${1} "${2}" ${3}
        return
    fi

    if [ "${connected}" == "true" ] && [ "${device}" == "" ]; then
        if [ "${message}" == "" ]; then
            message="Waiting for device"
        fi
        logWarning "${message}..."
        sleep 5s
        waitForDevice ${1} "${2}" ${3}
        return
    fi
}

for (( lastParam=1; lastParam<=$#; lastParam+=1 )); do
    paramValue="${!lastParam}"
    case ${paramValue} in
        "--package-name="*)
            packageName=`echo "${paramValue}" | sed -E "s/--package-name=(.*)/\1/"`
        ;;

        "--path-to-apk="*)
            pathToApk=`echo "${paramValue}" | sed -E "s/--path-to-apk=(.*)/\1/"`
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
            outputFolder="${projectName}/build/outputs/apk"
        ;;

        "--build="*)
            buildCommand=`echo "${paramValue}" | sed -E "s/--build=(.*)/\1/"`
            command="${command} assemble${buildCommand}"
        ;;

        "--clean"*)
            clean=" clean"
        ;;

        "--clear-data")
            clearData="--clear-data"
        ;;

        "--delete-apks")
            deleteApks="--delete-apks"
        ;;

        "--uninstall")
            uninstall="--uninstall"
            clearData=
            forceStop=
        ;;

        "--uninstall-only")
            clearData=
            forceStop=
            noInstall="--no-install"
            noBuild="--no-build"
            noLaunch="--no-launch"
            uninstall="--uninstall"
        ;;

        "--force-stop")
            forceStop="--force-stop"
        ;;

        "--offline")
            offline=" --offline"
        ;;

        "--no-build")
            noBuild=" --no-build"
        ;;

        "--no-install")
            noInstall=" --no-install"
        ;;

        "--no-launch")
            noLaunch=" --no-launch"
        ;;

        "--wait-for-device")
            waitForDevice="--wait-for-device"
        ;;

        "--only-build")
            noLaunch=" --no-launch"
            noInstall=" --no-install"
        ;;

        "*")
            echo "UNKNOWN PARAM: ${paramValue}";
        ;;
    esac
done

function verifyHasDevices() {
    local message=${1}

    if [ "${#deviceIds[@]}" == "0" ]; then
        logError "${message}"
        logError "No device found"
        exit 1
    fi
}

function printParam() {
    local paramName="${1}"
    local paramValue="${2}"
    if [ "${paramValue}" == "" ]; then
        return
    fi

    echo "${paramName}: ${paramValue}"
}

echo ----------
printParam "appName" "${appName}"
printParam "packageName" "${packageName}"
printParam "projectName" "${projectName}"
printParam "pathToApk" "${pathToApk}"
printParam "apkPattern" "${apkPattern}"
printParam "outputFolder" "${outputFolder}"

printParam "deviceIdParam" "${deviceIdParam}"

printParam "uninstall" "${uninstall}"
printParam "clearData" "${clearData}"
printParam "forceStop" "${forceStop}"
printParam "clean" "${clean}"
printParam "build" "${buildCommand}"
printParam "noBuild" "${noBuild}"
printParam "noInstall" "${noInstall}"
printParam "noLaunch" "${noLaunch}"
printParam "waitForDevice" "${waitForDevice}"


if [ "${packageName}" == "" ]; then
    printUsage "No package name defined"
fi

if [ ! -d "${projectName}" ]; then
    printUsage "No project module named: '${projectName}'"
fi

if [ "${command}" == "" ] && [ "${noBuild}" == "" ] && [ "${uninstall}" == "" ] && [ "${clearData}" == "" ] && [ "${deleteApks}" == "" ]; then
    printUsage "MUST specify build type or set flag --no-build"
fi

if [ "${outputFolder}" == "" ]; then
    printUsage "missing output folder"
fi

if [ "${appName}" == "" ]; then
    appName="${packageName}"
fi

if [ "${deviceIdParam}" == "" ] || [ "${deviceIdParam}" == "ALL" ] || [ "${deviceIdParam}" == "all" ]; then
    deviceIds=(`adb devices | grep -E "^[0-9a-zA-Z\-]+\s+?device$" | sed -E "s/([0-9a-zA-Z-]+).*/\1/"`)
    if [ "${deviceIdParam}" == "" ] && (("${#deviceIds[@]}" > "1")); then
        logError "More than one device connected, please specify which device: "
        logError "    --device-id=ALL"
        for deviceId in "${deviceIds[@]}"; do
            logError "    --device-id=${deviceId}"
        done

        exit 2
    fi
else
    deviceIds=(`echo "${deviceIdParam}"`)
fi

function yesOrNoQuestion() {
    local message=${1}
    local toExecuteYes=${2}
    local toExecuteNo=${3}

    echo
    logWarning "${message}"
    read  -n 1 -p "" response

    case "$response" in
        [yY])
                echo
                eval ${toExecuteYes}
            ;;
        [nN])
                echo
                eval ${toExecuteNo}
            ;;
        *)
                echo
                logError "Canceling..."
                exit 2
            ;;
    esac
}

function waitForDeviceImpl() {
    if [ "${waitForDevice}" == "" ]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
       waitForDevice ${deviceId} true
    done
}

function uninstallFromDevice() {
    local deviceId=${1}
    waitForDevice ${deviceId} true
    execute "Uninstalling '${appName}':" "${adbCommand} -s ${deviceId} uninstall ${packageName}"
}

function uninstallImpl() {
    if [ "${uninstall}" == "" ]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
        uninstallFromDevice "${deviceId}"
    done
}

function buildImpl() {
    if [ "${noBuild}" != "" ]; then
          return
    fi

    execute "deleting output folder:" "rm -rf ${outputFolder}"
    execute "Building '${appName}'..." "bash gradlew${clean}${command}${offline}" false
    checkExecutionError "Build error..."
}

function deleteApksImpl() {
    if [ "${deleteApks}" != "" ]; then
        execute "deleting output folder:" "rm -rf ${outputFolder}"
    fi
}

function clearDataImpl() {
    if [ "${clearData}" == "" ]; then
          return
    fi

    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId} true
        execute "Clearing data for '${appName}':" "${adbCommand} -s ${deviceId} shell pm clear ${packageName}"
    done
}

function forceStopImpl() {
    if [ "${forceStop}" == "" ]; then
        return
    fi

    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId} true
        execute "Force stopping Remote-Screen app..." "${adbCommand} -s ${deviceId} shell am force-stop ${packageName}"
    done
}


function installAppOnDevice() {
    local deviceId=${1}
    waitForDevice ${deviceId} true
    execute "Installing '${appName}':" "${adbCommand} -s ${deviceId} install -r -d ${pathToApk}" false |& tee error

    output=`cat error`
    echo "output: ${output}"
#    exit
    rm error

    if [[ "${output}" =~ "INSTALL_FAILED_UPDATE_INCOMPATIBLE" ]]; then
        yesOrNoQuestion "Apk Certificate changed, do you want to uninstall previous version? [y(yes)/n(no)/c(cancel)]" "uninstallFromDevice \"${deviceId}\"; installAppOnDevice \"${deviceId}\"" "logError \"COULD NOT INSTALL SOM\""
        return
    fi

    if [[ "${output}" =~ "INSTALL_PARSE_FAILED_NO_CERTIFICATES" ]]; then
        installAppOnDevice "${deviceId}"
        return
    fi

    if [[ "${output}" =~ "INSTALL_FAILED_VERSION_DOWNGRADE" ]]; then
        yesOrNoQuestion "Failed to install! trying to install an older version, Uninstall newer version? [y/n]" "uninstallFromDevice \"${deviceId}\"; installAppOnDevice \"${deviceId}\"" "logError \"COULD NOT INSTALL TABLET\"; exit 1"
        return
    fi

    if [[ "${output}" =~ "failed to install" ]]; then
        yesOrNoQuestion "Failed to install, Try again? [y/n]" "installAppOnDevice \"${deviceId}\"" "logError \"COULD NOT INSTALL SOM\"; exit 1"
        return
    fi
}

function installImpl() {
    if [ "${noInstall}" != "" ]; then
        return
    fi

    if [ ! -e "${outputFolder}" ]; then
        logError "Output folder does not exists... Build needed"
        exit 2
    fi

    if [ "${pathToApk}" == "" ]; then
        pathToApk=`find "${outputFolder}" -name "${apkPattern}"`
    fi

    if [ "${pathToApk}" == "" ]; then
        logError "Could not find apk in path '${outputFolder}', matching the pattern '${apkPattern}'"
        exit 2
    fi

    verifyHasDevices "Cannot install apk..."
    for deviceId in "${deviceIds[@]}"; do
        installAppOnDevice "${deviceId}"
    done
}

function launchImpl() {
    if [ "${noLaunch}" != "" ]; then
        return
    fi

        verifyHasDevices "Cannot launch app..."
        for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId} true
        execute "Launching '${appName}':" "${adbCommand} -s ${deviceId} shell am start -n ${packageName}/com.nu.art.cyborg.ui.ApplicationLauncher -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
    done
}

deleteApksImpl
forceStopImpl
clearDataImpl
uninstallImpl
buildImpl
installImpl
launchImpl


# For reference

#forceStopImpl
#clearDataImpl
#uninstallImpl
#buildImpl
#installImpl
#launchImpl
