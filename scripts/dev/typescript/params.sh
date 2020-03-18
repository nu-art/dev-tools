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
linkThunderstorm=
lint=
runTests=

launchBackend=
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

outputDir=dist
outputTestDir=dist-test

tsLogLevel=${LOG_LEVEL__INFO}
libsToRun=()

params=(ThunderstormHome mergeOriginRepo printEnv cloneThunderstorm buildThunderstorm pushNuArtMessage readOnly purge clean setup newVersion linkDependencies install build runTests testServiceAccount lint cleanDirt launchBackend launchFrontend envType promoteNuArtVersion promoteAppVersion deployBackend deployFrontend version publish)

function extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    "--help")
      printHelp
      ;;

    "--print-env")
      printEnv=true
      build=
      linkThunderstorm=
      linkDependencies=
      ;;

    "--debug")
      debug=true
      ;;

    "--merge-origin")
      mergeOriginRepo=true
      ;;

    "--use-thunderstorm-sources")
      cloneThunderstorm=true
      setup=true
      linkDependencies=true
      purge=true
      clean=true
      ;;

    "--push="*)
      pushNuArtMessage=$(regexParam "--push" "${paramValue}")
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
    "--use-library="* | "-ul="*)
      local lib=$(regexParam "--use-library|-ul" "${paramValue}")
      libsToRun+=("${lib}")
      ;;

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

    "--link" | "-l")
      linkDependencies=true
      ;;

    "--link-only" | "-lo")
      linkDependencies=true
      build=
      ;;

    "--no-build" | "-nb")
      build=
      ;;

    "--no-link" | "-nl")
      linkDependencies=
      linkThunderstorm=
      ;;

    "--no-thunderstorm" | "-nts")
      buildThunderstorm=
      ThunderstormHome=
      ;;

    "--thunderstorm-home="* | "-th="*)
      linkDependencies=true
      linkThunderstorm=true
      local temp=$(regexParam "--thunderstorm-home|-th" "${paramValue}")
      [[ "${temp}" ]] && ThunderstormHome="${temp}"
      ;;

    "--lint")
      lint=true
      ;;

    "--rebuild-on-change" | "-roc")
      listen=true
      build=
      ;;

    "--output-dir="* | "-od="*)
      outputDir=$(regexParam "--output-dir|-od" "${paramValue}")
      ;;

      #        ==== TEST =====
    "--test" | "-t")
      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      runTests=true
      ;;

    "--test="* | "-t="*)
      testServiceAccount=$(regexParam "--test|-t" "${paramValue}")
      runTests=true
      ;;

    "--output-test-dir="* | "-otd="*)
      outputTestDir=$(regexParam "--output-test-dir|-otd" "${paramValue}")
      ;;

      #        ==== LAUNCH =====
    "--launch" | "-la")
      launchBackend=true
      launchFrontend=true
      ;;

    "--launch-backend" | "-lb")
      launchBackend=true
      ;;

    "--launch-frontend" | "-lf")
      launchFrontend=true
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
      envType=$(regexParam "--set-env|-se" "${paramValue}")
      ;;

    "--fallback-env="* | "-fe="*)
      fallbackEnv=$(regexParam "--fallback-env|-fe" "${paramValue}")
      ;;

    "--set-version="* | "-sv="*)
      newAppVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      linkDependencies=true
      build=true
      lint=true
      ;;

      #        ==== OTHER =====
    "--log="*)
      local _logLevelKey=$(regexParam "--log" "${paramValue}")
      local logLevelKey=LOG_LEVEL__${_logLevelKey^^}
      tsLogLevel=${!logLevelKey}
      [[ ! ${tsLogLevel} ]] && tsLogLevel=${LOG_LEVEL__INFO}
      ;;

    "--clean-dirt")
      cleanDirt=true
      clean=true
      ;;

    "--flag-dirty="*)
      dirtyLib=$(regexParam "--flag-dirty" "${paramValue}")
      ;;

    "--publish" | "-p")
      clean=true
      build=true
      publish=true
      lint=true
      ;;

    "--version-nu-art="* | "-vn="*)
      promoteNuArtVersion=$(regexParam "--version-nu-art|-vn" "${paramValue}")
      linkDependencies=true
      build=true
      lint=true
      ;;

      #        ==== ERRORS & DEPRECATION =====

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done
}
