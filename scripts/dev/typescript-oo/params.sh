#!/bin/bash

ts_debug=

ts_dependencies=
ts_purge=
ts_clean=
ts_install=
ts_compile=true
ts_watch=
ts_link=
ts_linkThunderstorm=
ts_lint=
ts_test=
ts_publish=

checkCircularImports=
launchBackend=
launchFrontend=

envType=
deployBackend=
deployFrontend=

promoteThunderstormVersion=
promoteAppVersion=
newAppVersion=
printEnv=

outputDir=dist
outputTestDir=dist-test

activeLibs=()
ts_LogLevel=${LOG_LEVEL__INFO}

params=(
  envType
  ThunderstormHome
  printEnv
  testServiceAccount
  ts_dependencies
  ts_purge
  ts_clean
  ts_install
  ts_compile
  ts_watch
  ts_link
  ts_linkThunderstorm
  ts_lint
  ts_test
  ts_launch
  ts_publish
  checkCircularImports
  deployBackend
  deployFrontend
  "activeLibs[@]"
  newVersion
  promoteThunderstormVersion
  version
  promoteAppVersion

)

extractParams() {
  printCommand "$@"

  for paramValue in "${@}"; do
    case "${paramValue}" in
    #        ==== General ====
    "--help" | "-h")
      #￿￿￿￿DOC: This help menu

      printHelp "${BASH_SOURCE%/*}/params.sh"
      ;;

    "--dependencies-tree" | "-dt")
      #DOC: Will print the projects packages dependencie tree into the .trash folder

      ts_dependencies=true
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

      #        ==== CLEAN ====
    "--purge" | "-p")
      #DOC: Will delete the node_modules folder in all project packages
      #DOC: Will perform --clean --setup

      ts_purge=true
      ts_clean=true
      ts_setup=true
      ;;

    "--clean" | "-c")
      #DOC: Will delete the output(dist) & test output(dist-test) folders in all project packages

      ts_clean=true
      ;;

      #        ==== BUILD ====
    "--use-package="* | "-up="*)
      #DOC: Would ONLY run the script in the context of the specified project packages
      #PARAM=project-package-folder

      local lib=$(regexParam "--use-package|-up" "${paramValue}")
      activeLibs+=("${lib}")
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
      ts_setup=true
      ts_link=true
      ;;

    "--link" | "-l")
      #DOC: Would link dependencies between project packages

      ts_link=true
      ;;

    "--link-only" | "-lo")
      #DOC: Would ONLY link dependencies between project packages
      ts_link=true
      ts_compile=
      ;;

    "--no-build" | "-nb")
      #DOC: Skip the build step
      ts_compile=
      ;;

    "--thunderstorm-home="* | "-th="*)
      #DOC: Will link the output folder of the libraries of thunderstorm that exists under the give path
      #PARAM=path-to-thunderstorm-folder

      ts_link=true
      ts_linkThunderstorm=true

      local temp=$(regexParam "--thunderstorm-home|-th" "${paramValue}")
      [[ "${temp}" ]] && ThunderstormHome="${temp}"
      ;;

    "--lint")
      #DOC: Run lint on all the project packages
      ts_lint=true
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
      ts_watch=true
      ts_compile=true
      ;;

      #        ==== TEST ====
    "--test" | "-t")
      #DOC: Run the tests in all the project packages
      #NOTE: Running this way expecting the "testServiceAccount" variable to be defined gloabally

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      ts_test=true
      ;;

    "--test="* | "-t="*)
      #DOC: Run the tests in all the project packages
      #PARAM=path-to-firebase-service-account

      testServiceAccount=$(regexParam "--test|-t" "${paramValue}")
      ts_test=true
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
      launchFrontend=
      ;;

    "--launch-frontend" | "-lf")
      #DOC: Will launch ONLY frontend

      launchFrontend=true
      launchBackend=
      ;;

      #        ==== DEPLOY ====
    "--deploy" | "-d")
      #DOC: Will compile, build, lint and deploy both frontend & backend

      deployBackend=true
      deployFrontend=true
      ts_lint=true
      ;;

    "--deploy-backend" | "-db")
      #DOC: Will compile, build, lint and deploy ONLY the backend

      deployBackend=true
      ts_lint=true
      ;;

    "--deploy-frontend" | "-df")
      #DOC: Will compile, build, lint and deploy ONLY the frontend

      deployFrontend=true
      ts_lint=true
      ;;

    "--set-version="* | "-sv="*)
      #DOC: Set application version before deploy
      #PARAM=x.y.z

      newAppVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      ts_link=true
      ts_compile=true
      ts_lint=true
      ;;

      #        ==== OTHER ====

    "--debug")
      #DOC: Will print the parameters the script is running with
      setDebugLog true
      ts_LogLevel=${LOG_LEVEL__DEBUG}

      ts_debug=true
      ;;

    "--log="*)
      #DOC: Set the script log level
      #PARAM=[verbose | debug | info | warning | error]
      #DEFAULT_PARAM=info

      local _logLevelKey=$(regexParam "--log" "${paramValue}")
      local logLevelKey=LOG_LEVEL__${_logLevelKey^^}
      ts_LogLevel=${!logLevelKey}
      [[ ! ${ts_LogLevel} ]] && ts_LogLevel=${LOG_LEVEL__INFO}

      ;;

    "--quick-deploy" | "-qd")
      #DOC: Will deploy both frontend & backend, without any other lifecycle action
      #WARNING: Use only if you REALLY understand the lifecycle of the project and script!!

      ts_lint=
      ts_compile=
      ts_link=
      ;;

    "--publish="* | "--publish")
      #DOC: Will publish thunderstorm && promote thunderstorm version
      #PARAM=[patch | minor | major]
      #DEFAULT_PARAM=patch
      #WARNING: ONLY used for publishing Thunderstorm!!

      if [[ "${paramValue}" == "--publish" ]]; then
        promoteThunderstormVersion=patch
      else
        promoteThunderstormVersion=$(regexParam "--publish" "${paramValue}")
      fi

      case "${promoteThunderstormVersion}" in
      "patch" | "minor" | "major") ;;

      *)
        throwError "Bad version type: ${promoteThunderstormVersion}" 2
        ;;

      esac

      ts_link=true
      ts_clean=true
      ts_compile=true
      ts_publish=true
      ts_lint=true
      ;;

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done

  printDebugParams "${ts_debug}" "${params[@]}"
}
