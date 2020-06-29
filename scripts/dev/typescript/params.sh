#!/bin/bash

debug=

purge=
clean=

setup=
build=true
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
printDependencies=

modulesPackageName=()

outputDir=dist
outputTestDir=dist-test

tsLogLevel=${LOG_LEVEL__INFO}
libsToRun=()

params=(libsToRun[@] ThunderstormHome printEnv printDependencies purge clean setup newVersion linkDependencies install build runTests testServiceAccount lint checkCircularImports launchBackend launchFrontend envType promoteThunderstormVersion promoteAppVersion deployBackend deployFrontend version publish)

extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    #        ==== General ====
    "--help" | "-h")
      #￿￿￿￿DOC: This help menu

      printHelp "${BASH_SOURCE%/*}/params.sh"
      ;;

    "--dependencies-tree" | "-dt")
      #DOC: Will print the projects packages dependencie tree into the .trash folder

      printDependencies=true
      ;;

    "--print-env")
      #DOC: Will print the current versions of the important tools

      printNpmPackageVersion typescript
      printNpmPackageVersion tslint
      printNpmPackageVersion firebase-tools
      printNpmPackageVersion sort-package-json

      logDebug "node version: $(node -v)"
      logDebug "npm version: $(npm -v)"
      logDebug "bash version: $(getBashVersion)"
      exit 0
      ;;

    "--debug")
      #DOC: Will print the parameters the script is running with

      debug=true
      ;;

      #        ==== CLEAN ====
    "--purge" | "-p")
      #DOC: Will delete the node_modules folder in all project packages
      #DOC: Will perform --clean --setup

      purge=true
      clean=true
      setup=true
      ;;

    "--clean" | "-c")
      #DOC: Will delete the output(dist) & test output(dist-test) folders in all project packages

      clean=true
      ;;

      #        ==== BUILD ====
    "--use-package="* | "-up="*)
      #DOC: Would ONLY run the script in the context of the specified project packages
      #PARAM=project-package-folder

      local lib=$(regexParam "--use-package|-up" "${paramValue}")
      libsToRun+=("${lib}")
      ;;

    "--set-env="* | "-se="*)
      #DOC: Will set the .config-${environment}.json as the current .config.json and prepare it as base 64 for local usage
      #PARAM=environment
      envType=$(regexParam "--set-env|-se" "${paramValue}")
      ;;

    "--fallback-env="* | "-fe="*)
      #DOC: When setting env some of the files might be missing and would fallback to the provided env
      #PARAM=environment
      fallbackEnv=$(regexParam "--fallback-env|-fe" "${paramValue}")
      ;;

    "--setup" | "-s")
      #DOC: Will run 'npm install' in all project packages
      #DOC: Will perform --link
      setup=true
      linkDependencies=true
      ;;

    "--link" | "-l")
      #DOC: Would link dependencies between project packages

      linkDependencies=true
      ;;

    "--link-only" | "-lo")
      #DOC: Would ONLY link dependencies between project packages
      linkDependencies=true
      build=
      ;;

    "--no-build" | "-nb")
      #DOC: Skip the build step
      build=
      ;;

    "--thunderstorm-home" | "-th")
      #DOC: Will link the output folder of the libraries of thunderstorm that exists under the give path
      #NOTE: MUST have ThunderstormHome env variable defined and point to the Thunderstorm sample project

      [[ ! "${ThunderstormHome}" ]] && throwError "ThunderstormHome must be defined as an Environment variable" 2
      linkDependencies=true
      linkThunderstorm=true
    ;;

    "--thunderstorm-home="* | "-th="*)
      #DOC: Will link the output folder of the libraries of thunderstorm that exists under the give path
      #PARAM=path-to-thunderstorm-folder

      linkDependencies=true
      linkThunderstorm=true
      local temp=$(regexParam "--thunderstorm-home|-th" "${paramValue}")
      [[ "${temp}" ]] && ThunderstormHome="${temp}"
      ;;

    "--lint")
      #DOC: Run lint on all the project packages
      lint=true
      ;;

    "--output-dir="* | "-od="*)
      #DOC: Set the output dir name/path (default: dist)
      #PARAM=path-to-output-folder

      outputDir=$(regexParam "--output-dir|-od" "${paramValue}")
      ;;

    "--check-imports" | "-ci")
      #DOC: Will check for circular import in files...
      checkCircularImports=true
      ;;

    "--rebuild-on-change" | "-roc")
      # FUTURE: will build and listen for changes in the libraries
      listen=true
      build=
      ;;

      #        ==== TEST ====
    "--test" | "-t")
      #DOC: Run the tests in all the project packages
      #NOTE: Running this way expecting the "testServiceAccount" variable to be defined globally

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      runTests=true
      ;;

    "--test="* | "-t="*)
      #DOC: Run the tests in all the project packages
      #PARAM=path-to-firebase-service-account

      testServiceAccount=$(regexParam "--test|-t" "${paramValue}")
      runTests=true
      ;;

    "--output-test-dir="* | "-otd="*)
      #DOC: Set the tests output dir name/path (default: dist-test)
      #PARAM=path-to-tests-output-folder

      outputTestDir=$(regexParam "--output-test-dir|-otd" "${paramValue}")
      ;;

      #        ==== LAUNCH ====
    "--launch" | "-la")
      #DOC: Will launch both frontend & backend

      launchBackend=true
      launchFrontend=true
      ;;

    "--launch-backend" | "-lb")
      #DOC: Will launch ONLY backend

      launchBackend=true
      ;;

    "--launch-frontend" | "-lf")
      #DOC: Will launch ONLY frontend

      launchFrontend=true
      ;;

      #        ==== DEPLOY ====
    "--deploy" | "-d")
      #DOC: Will compile, build, lint and deploy both frontend & backend

      deployBackend=true
      deployFrontend=true
      lint=true
      ;;

    "--deploy-backend" | "-db")
      #DOC: Will compile, build, lint and deploy ONLY the backend

      deployBackend=true
      lint=true
      ;;

    "--deploy-frontend" | "-df")
      #DOC: Will compile, build, lint and deploy ONLY the frontend

      deployFrontend=true
      lint=true
      ;;

    "--set-version="* | "-sv="*)
      #DOC: Set application version before deploy
      #PARAM=x.y.z

      newAppVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      linkDependencies=true
      build=true
      lint=true
      ;;

      #        ==== OTHER ====
    "--log="*)
      #DOC: Set the script log level
      #PARAM=[verbose | debug | info | warning | error]
      #DEFAULT_PARAM=info

      local _logLevelKey=$(regexParam "--log" "${paramValue}")
      local logLevelKey=LOG_LEVEL__${_logLevelKey^^}
      tsLogLevel=${!logLevelKey}
      [[ ! ${tsLogLevel} ]] && tsLogLevel=${LOG_LEVEL__INFO}

      ;;

    "--quick-deploy" | "-qd")
      #DOC: Will deploy both frontend & backend, without any other lifecycle action
      #WARNING: Use only if you REALLY understand the lifecycle of the project and script!!

      lint=
      build=
      linkDependencies=
      ;;

    "--publish="* | "--publish")
      #DOC: Will publish thunderstorm && promote thunderstorm version
      #PARAM=[patch | minor | major]
      #DEFAULT_PARAM=patch
      #WARNING: ONLY used for publishing Thunderstorm!!

      if [[ "${paramValue}" == "--publish" ]]; then
        promoteThunderstormVersion="patch"
      else
        promoteThunderstormVersion=$(regexParam "--publish" "${paramValue}")
      fi

      linkDependencies=true
      clean=true
      build=true
      publish=true
      lint=true
      ;;

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done
}
