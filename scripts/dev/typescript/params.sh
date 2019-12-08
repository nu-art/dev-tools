#!/bin/bash

debug=
mergeOriginRepo=
cloneThunderstorm=
pushNuArtMessage=

dirtyLib=
cleanDirt=

purge=
clean=

setup=
readOnly=true
build=true
install=true
listen=
linkDependencies=true
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
printEnv=

buildThunderstorm=true

modulesPackageName=()
modulesVersion=()

params=(mergeOriginRepo printEnv cloneThunderstorm buildThunderstorm pushNuArtMessage readOnly purge clean setup newVersion linkDependencies install build lint cleanDirt launchBackend runBackendTests launchFrontend envType promoteNuArtVersion promoteAppVersion deployBackend deployFrontend version publish)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--help")
                printHelp
            ;;

            "--print-env")
                printEnv=true
            ;;

            "--debug")
                debug=true
            ;;

            "--merge-origin")
                mergeOriginRepo=true
            ;;

            "--use-thunderstorm-sources")
                cloneThunderstorm=true
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

            "--allow-write" | "-aw")
                readOnly=
            ;;

            "--link-only" | "-lo")
                linkDependencies=true
                build=
            ;;

            "--no-build" | "-nb")
                build=
            ;;

            "--no-thunderstorm" | "-nts")
                buildThunderstorm=
            ;;

            "--lint")
                lint=true
            ;;

            "--listen" | "-l")
                listen=true
                build=
            ;;


#        ==== TEST =====
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

            "--launch-both" | "--tmux" | "-lt")
                envType=dev
                launchTmux=true

                [[ `isMacOS` ]] && { throwError "The tmux feature has not been tested on MacOS."; }

                command -v tmux >/dev/null 2>&1 || { throwError "Please install tmux through your package manager."; }
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


#        ==== OTHER =====
            "--clean-dirt")
                cleanDirt=true
                clean=true
            ;;

            "--flag-dirty="*)
                dirtyLib=`regexParam "--flag-dirty" "${paramValue}"`
            ;;

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

            *)
                logWarning "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}
