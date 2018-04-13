#!/bin/bash

bashVersion=`bash --version | grep version | sed -E "s/.* version (.).*/\1/"`

source ${BASH_SOURCE%/*}/_generic-tools.sh

source ${BASH_SOURCE%/*}/../utils/tools.sh
source ${BASH_SOURCE%/*}/../utils/coloring.sh
source ${BASH_SOURCE%/*}/../utils/log-tools.sh
source ${BASH_SOURCE%/*}/../utils/error-handling.sh

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
        "--packageName="*)
            packageName=`echo "${paramValue}" | sed -E "s/--packageName=(.*)/\1/"`
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
            _command=`echo "${paramValue}" | sed -E "s/--build=(.*)/\1/"`
            command="${command} assemble${_command}"
        ;;

        "--clear-data")
            clearData="--clear-data"
        ;;

        "--uninstall")
            uninstall="--uninstall"
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

        "--only-build")
            noLaunch=" --no-launch"
            noInstall=" --no-install"
        ;;

        "*")
            echo "UNKNOWN PARAM: ${paramValue}";
        ;;
    esac
done
echo

if [ "${deviceIdParam}" == "" ] || [ "${deviceIdParam}" == "ALL" ] || [ "${deviceIdParam}" == "all" ]; then
    deviceIds=(`adb devices | grep -E "^[0-9a-zA-Z]+\s+?device$" | sed -E "s/([0-9a-zA-Z]+).*/\1/"`)
else
    deviceIds=("${deviceIdParam}")
fi

if [ "${packageName}" == "" ]; then
    printUsage
fi

if [ ! -d "${projectName}" ]; then
    printUsage "No project module named: '${projectName}'"
fi

if [ "${command}" == "" ] && [ "${noBuild}" == "" ] && [ "${uninstall}" == "" ] && [ "${clearData}" == "" ]; then
    printUsage "MUST specify build type or set flag --no-build"
fi

if [ "${outputFolder}" == "" ]; then
    printUsage "missing output folder"
fi

if [ "${appName}" == "" ]; then
    appName="${packageName}"
fi

if [ "${uninstall}" != "" ]; then
    for deviceId in "${deviceIds[@]}"; do
       waitForDevice ${deviceId} true
       execute "Uninstalling '${appName}':" "${adbCommand} -s ${deviceId} uninstall ${packageName}"
    done
fi

if [ "${clearData}" != "" ]; then
    for deviceId in "${deviceIds[@]}"; do
        waitForDevice ${deviceId} true
        execute "Clearing data for '${appName}':" "${adbCommand} -s ${deviceId} shell pm clear ${packageName}"
    done
fi

if [  "${command}" == "" ]; then
    exit 0
fi

if [ "${noBuild}" == "" ]; then
    if [ -e "${outputFolder}" ]; then
        execute "deleting output folder:" "rm -rf ${outputFolder}"
    fi

    execute "Building '${appName}'..." "bash gradlew ${command}${offline}" false
    checkExecutionError "Build error..."
fi

pathToApk=`find "${outputFolder}" -name '*.apk'`
    for deviceId in "${deviceIds[@]}"; do
    if [ "${noInstall}" == "" ]; then
        waitForDevice ${deviceId} true
        execute "Installing '${appName}':" "${adbCommand} -s ${deviceId} install -r ${pathToApk}" false
    fi

    if [ "${noLaunch}" == "" ]; then
        waitForDevice ${deviceId} true
        execute "Launching '${appName}':" "${adbCommand} -s ${deviceId} shell am start -n ${packageName}/com.nu.art.cyborg.ui.ApplicationLauncher -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
    fi
done