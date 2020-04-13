#!/bin/bash

debug=

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
checkCircularImports=
runTests=

launchBackend=
launchFrontend=

envType=
deployBackend=
deployFrontend=

promoteThunderstormVersion=
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

params=(ThunderstormHome printEnv buildThunderstorm readOnly purge clean setup newVersion linkDependencies install build runTests testServiceAccount lint checkCircularImports launchBackend launchFrontend envType promoteThunderstormVersion promoteAppVersion deployBackend deployFrontend version publish)

function extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    #        ==== General ====
    "--help" | "-h")
      #This help menu

      printHelp
      ;;

    "--print-env")
      #Will print the current versions of the important tools

      printEnv=true
      build=
      linkThunderstorm=
      linkDependencies=
      ;;

    "--debug")
      #Will print the parameters the script is running with

      debug=true
      ;;

      #        ==== CLEAN ====
    "--purge" | "-p")
      #Will delete the node_modules folder in all project packages
      #Will perform --clean --setup

      purge=true
      clean=true
      setup=true
      ;;

    "--clean" | "-c")
      #Will delete the output(dist) & test output(dist-test) folders in all project packages

      clean=true
      ;;

      #        ==== BUILD ====
    "--use-package="* | "-up="*)
      #Would ONLY run the script in the context of the specified project packages
      #PARAM=project-package-folder

      local lib=$(regexParam "--use-package|-up" "${paramValue}")
      libsToRun+=("${lib}")
      ;;

    "--set-env="* | "-se="*)
      #Will set the .config-\${envType}.json as the current .config.json and prepare it as base 64 for local usage
      #PARAM=environment
      envType=$(regexParam "--set-env|-se" "${paramValue}")
      ;;

    "--fallback-env="* | "-fe="*)
      #When setting env some of the files might be missing and would fallback to the provided env
      #PARAM=environment
      fallbackEnv=$(regexParam "--fallback-env|-fe" "${paramValue}")
      ;;

    "--setup" | "-s")
      #Will run 'npm install' in all project packages
      #Will perform --link
      setup=true
      linkDependencies=true
      ;;

    "--link" | "-l")
      #Would link dependencies between project packages

      linkDependencies=true
      ;;

    "--link-only" | "-lo")
      #Would ONLY link dependencies between project packages
      linkDependencies=true
      build=
      ;;

    "--no-build" | "-nb")
      #Skip the build step
      build=
      ;;

    "--no-thunderstorm" | "-nts")
      #Completely ignore Thunderstorm infra whether it exists or not in the project
      buildThunderstorm=
      ThunderstormHome=
      ;;

    "--thunderstorm-home="* | "-th="*)
      #Will link the output folder of the libraries of thunderstorm that exists under the give path
      #PARAM=path-to-thunderstorm-folder

      linkDependencies=true
      linkThunderstorm=true
      local temp=$(regexParam "--thunderstorm-home|-th" "${paramValue}")
      [[ "${temp}" ]] && ThunderstormHome="${temp}"
      ;;

    "--lint")
      #Run lint on all the project packages
      lint=true
      ;;

    "--output-dir="* | "-od="*)
      #Set the output dir name/path (default: dist)
      #PARAM=path-to-output-folder

      outputDir=$(regexParam "--output-dir|-od" "${paramValue}")
      ;;

    "--check-imports" | "-ci")
      #Will check for circular import in files...
      checkCircularImports=true
      ;;

    "--rebuild-on-change" | "-roc")
      # FUTURE: will build and listen for changes in the libraries
      listen=true
      build=
      ;;

      #        ==== TEST ====
    "--test" | "-t")
      #Run the tests in all the project packages
      #NOTE: Running this way expecting the "testServiceAccount" variable to be defined gloabally

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      runTests=true
      ;;

    "--test="* | "-t="*)
      #Run the tests in all the project packages
      #PARAM=path-to-firebase-service-account

      testServiceAccount=$(regexParam "--test|-t" "${paramValue}")
      runTests=true
      ;;

    "--output-test-dir="* | "-otd="*)
      #Set the tests output dir name/path (default: dist-test)
      #PARAM=path-to-tests-output-folder

      outputTestDir=$(regexParam "--output-test-dir|-otd" "${paramValue}")
      ;;

      #        ==== LAUNCH ====
    "--launch" | "-la")
      #Will launch both frontend & backend

      launchBackend=true
      launchFrontend=true
      ;;

    "--launch-backend" | "-lb")
      #Will launch ONLY backend

      launchBackend=true
      ;;

    "--launch-frontend" | "-lf")
      #Will launch ONLY frontend

      launchFrontend=true
      ;;

      #        ==== DEPLOY ====
    "--deploy" | "-d")
      #Will compile, build, lint and deploy both frontend & backend

      deployBackend=true
      deployFrontend=true
      lint=true
      ;;

    "--deploy-backend" | "-db")
      #Will compile, build, lint and deploy ONLY the backend

      deployBackend=true
      lint=true
      ;;

    "--deploy-frontend" | "-df")
      #Will compile, build, lint and deploy ONLY the frontend

      deployFrontend=true
      lint=true
      ;;

    "--quick-deploy" | "-qd")
      #WARNING: Use only if you REALLY understand the lifecycle of the project and script!!
      #Will deploy both frontend & backend, without any other lifecycle action

      lint=
      build=
      install=
      linkDependencies=
      ;;

    "--set-version="* | "-sv="*)
      #Set application version before deploy
      #PARAM=x.y.z

      newAppVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      linkDependencies=true
      build=true
      lint=true
      ;;

      #        ==== OTHER ====
    "--log="*)
      #Set the script log level
      #PARAM=[verbose | debug | info | warning | error]

      local _logLevelKey=$(regexParam "--log" "${paramValue}")
      local logLevelKey=LOG_LEVEL__${_logLevelKey^^}
      tsLogLevel=${!logLevelKey}
      [[ ! ${tsLogLevel} ]] && tsLogLevel=${LOG_LEVEL__INFO}
      ;;

    "--publish="*)
      #IGNORE: Will publish thunderstorm && promote thunderstorm version
      #PARAM=[patch | minor | major]

      promoteThunderstormVersion=$(regexParam "--publish" "${paramValue}")
      linkDependencies=true
      clean=true
      build=true
      publish=true
      lint=true
      ;;

    "--publish")
      #IGNORE: Will publish thunderstorm && promote thunderstorm version to patch

      promoteThunderstormVersion=patch
      linkDependencies=true
      clean=true
      build=true
      publish=true
      lint=true
      ;;

      #        ==== ERRORS & DEPRECATION ====

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done
}
