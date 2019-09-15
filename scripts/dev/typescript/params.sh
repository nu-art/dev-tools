#!/bin/bash

debug=
mergeOriginRepo=
cloneNuArt=
pushNuArtMessage=

dirtyLib=
cleanDirt=

purge=
clean=

setup=
install=true
listen=
linkDependencies=true
build=true
lint=

launchBackend=
runBackendTests=
launchFrontend=

envType=
deployBackend=
deployFrontend=

promoteNuArtVersion=
promoteAppVersion=
publish=
newAppVersion=

modulesPackageName=()
modulesVersion=()

params=(mergeOriginRepo cloneNuArt pushNuArtMessage purge clean setup newVersion linkDependencies install build lint cleanDirt launchBackend runBackendTests launchFrontend envType promoteNuArtVersion promoteAppVersion deployBackend deployFrontend version publish)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--help")
                printHelp
            ;;

            "--debug")
                debug=true
            ;;

            "--merge-origin")
                mergeOriginRepo=true
            ;;

            "--nu-art")
                cloneNuArt=true
            ;;

            "--push="*)
                pushNuArtMessage=`regexParam "--push" "${paramValue}"`
            ;;

#        ==== CLEAN =====
            "--purge")
                purge=true
                clean=true
            ;;

            "--clean")
                clean=true
            ;;


#        ==== BUILD =====
            "--setup" | "-s")
                setup=true
                linkDependencies=true
            ;;

            "--unlink" | "-u")
                setup=true
            ;;

            "--link-only" | "-lo")
                linkDependencies=true
                build=
            ;;

            "--clean-dirt")
                cleanDirt=true
                clean=true
            ;;

            "--flag-dirty="*)
                dirtyLib=`regexParam "--flag-dirty" "${paramValue}"`
            ;;

            "--no-build" | "-nb")
                build=
            ;;

            "--lint")
                lint=true
            ;;

            "--test-modules" | "-tm")
                testModules=true
            ;;

            "--run-backend-tests" | "-rbt")
                runBackendTests=true
                launchFrontend=
                build=
            ;;

            "--launch-backend-test-mode" | "-lbtm")
                launchBackend=true
                launchFrontend=
                linkDependencies=true
                envType=test
                build=
            ;;

            "--listen" | "-l")
                listen=true
                build=
            ;;


#        ==== DEPLOY =====
            "--deploy" | "-d")
                deployBackend=true
                deployFrontend=true
                lint=true
            ;;

            "--deploy-backend" | "-db")
                deployBackend=true
                lint=true
            ;;

            "--deploy-frontend" | "-df")
                deployFrontend=true
                lint=true
            ;;

            "--quick-deploy" | "-qd")
                lint=
                build=
                install=
                linkDependencies=
            ;;

            "--set-env="* | "-se="*)
                envType=`regexParam "--set-env|-se" "${paramValue}"`
            ;;

            "--set-version="* | "-sv="*)
                newAppVersion=`regexParam "--set-version|-sv" "${paramValue}"`
                linkDependencies=true
                build=true
                lint=true
            ;;

#        ==== LAUNCH =====
            "--launch" | "-la")
                envType=dev
                launchBackend=true
                launchFrontend=true
            ;;

            "--launch-backend" | "-lb")
                envType=dev
                launchBackend=true
            ;;

            "--launch-frontend" | "-lf")
                launchFrontend=true
            ;;

#        ==== PUBLISH =====
            "--publish" | "-p")
                clean=true
                build=true
                publish=true
                lint=true
            ;;

            "--version-nu-art="* | "-vn="*)
                promoteNuArtVersion=`regexParam "--version-nu-art|-vn" "${paramValue}"`
                linkDependencies=true
                build=true
                lint=true
            ;;

#        ==== ERRORS & DEPRECATION =====
            "--get-config-backend"*)
                logWarning "COMMAND IS DEPRECATED... USE --get-backend-config"
            ;;

            "-gcb")
                logWarning "COMMAND IS DEPRECATED... USE -gbc"
            ;;

            "--set-config-backend"*)
                logWarning "COMMAND IS DEPRECATED... USE --set-backend-config"
            ;;

            "-scb"*)
                logWarning "COMMAND IS DEPRECATED... USE -sbc"
            ;;

            *)
                logWarning "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}
