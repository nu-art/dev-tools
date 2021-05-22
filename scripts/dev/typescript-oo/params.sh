#!/bin/bash

ts_debug=

ts_dependencies=
ts_purge=
ts_clean=
ts_installGlobals=
ts_installPackages=
ts_compile=true
ts_watch=
ts_link=
ts_linkThunderstorm=
ts_lint=
ts_runTests=
ts_publish=
ts_fileToExecute="index.js"

checkCircularImports=

envType=

promoteThunderstormVersion=
promoteAppVersion=
newAppVersion=
printEnv=

outputDir=dist
outputTestDir=dist-test

ts_generate=()
ts_launch=()
ts_deploy=()
ts_testsToRun=()
ts_activeLibs=()
ts_LogLevel=${LOG_LEVEL__INFO}

params=(
  envType
  ThunderstormHome
  printEnv
  testServiceAccount
  ts_dependencies
  ts_purge
  ts_clean
  ts_installGlobals
  ts_installPackages
  ts_compile
  ts_watch
  ts_link
  ts_linkThunderstorm
  ts_lint
  ts_runTests
  ts_publish
  ts_fileToExecute
  "ts_generate[@]"
  "ts_launch[@]"
  "ts_deploy[@]"
  "ts_activeLibs[@]"
  "ts_testsToRun[@]"
  checkCircularImports
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
      #DOC: This help menu

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
      #DOC: Will perform --clean --install

      ts_purge=true
      ts_clean=true
      ts_installPackages=true
      ts_link=true
      ;;

    "--clean" | "-c")
      #DOC: Will delete the output(dist) & test output(dist-test) folders in all project packages

      ts_clean=true
      ts_link=true
      ;;

      #        ==== BUILD ====
    "--use-package="* | "-up="*)
      #DOC: Would ONLY run the script in the context of the specified project packages
      #PARAM=project-package-folder

      local lib=$(regexParam "--use-package|-up" "${paramValue}")
      ts_activeLibs+=("${lib}")
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
      #WARNING: --setup / -s are deprecated... use --install or -i
      logWarning "--setup / -s are deprecated... use --install or -i"
      exit 2
      ;;

    "--install" | "-i")
      #DOC: Will run 'npm install' in all project packages
      #DOC: Will perform --link
      ts_installGlobals=true
      ts_installPackages=true
      ts_link=true
      ;;

    "--install-packages" | "-ip")
      #DOC: Will run 'npm install' in all project packages
      #DOC: Will perform --link

      ts_installPackages=true
      ts_link=true
      ;;

    "--generate" | "-g")
      ts_generate+=(${backendApps[@]})
      ts_generate+=(${frontendApps[@]})
      ts_link=
      ts_compile=
      ;;

    "--generate="* | "-g="*)
      #DOC: Will generate sources in the apps if needed
      ts_generate+=($(regexParam "--generate|-g" "${paramValue}"))
      ts_link=
      ts_compile=
      ;;

    "--link" | "-ln")
      #DOC: Would link dependencies between project packages

      ts_link=true
      ;;

    "--link-only" | "-lo")
      #DOC: Would ONLY link dependencies between project packages

      ts_link=true
      ts_compile=
      ;;

    "--no-build" | "-nb")
      #DOC: Skip the build and link steps
      ts_compile=
      ts_link=

      ;;

    "--thunderstorm-home" | "-th")
      #DOC: Will link the output folder of the libraries of thunderstorm that exists under the give path
      #NOTE: MUST have ThunderstormHome env variable defined and point to the Thunderstorm sample project

      [[ ! "${ThunderstormHome}" ]] && throwError "ThunderstormHome must be defined as an Environment variable" 2
      ts_link=true
      ts_linkThunderstorm=true
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

    "--watch" | "-w")
      # FUTURE: will build and listen for changes in the libraries
      ts_watch=true
      ts_compile=true
      CONST_BuildWatchFile="$(pwd)/.trash/watch.txt"

      ;;

      #        ==== TEST ====
    "--test" | "-t")
      #DOC: Run the tests in all the project packages
      #NOTE: Running this way expecting the "testServiceAccount" variable to be defined gloabally

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      ts_runTests=true
      ;;

    "--test="* | "-t="*)
      #DOC: Specify tests you want to run
      #PARAM="the label of the test you want to run"

      local testToRun="$(regexParam "--test|-t" "${paramValue}")"
      ts_testsToRun+=("${testToRun}")
      ts_runTests=true
      ;;

    "--account="* | "-a="*)
      #DOC: Run the tests in all the project packages
      #PARAM=path-to-firebase-service-account

      testServiceAccount=$(regexParam "--account|-a" "${paramValue}")
      ts_runTests=true
      ;;

    "--output-test-dir="* | "-otd="*)
      #DOC: Set the tests output dir name/path (default: dist-test)
      #PARAM=path-to-tests-output-folder

      outputTestDir=$(regexParam "--output-test-dir|-otd" "${paramValue}")
      ;;

      #        ==== Apps ====
    "--launch="* | "-l="*)
      #DOC: It will add the provided App to the launch list
      ts_launch+=($(regexParam "--launch|-l" "${paramValue}"))
      ;;

    "--file="* | "-f="*)
      #DOC: The file name to launch
      #NOTE: Apply on to the executable apps

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      ts_fileToExecute=$(regexParam "--file|-f" "${paramValue}")
      ;;

    "--launch-frontend" | "-lf")
      #DOC: Will add the app-frontend to the launch list
      ts_launch+=(app-frontend)
      ;;

    "--launch-backend" | "-lb")
      #DOC: Will add the app-backend to the launch list
      ts_launch+=(app-backend)
      ;;

    "--deploy" | "-d")
      ts_deploy+=(${backendApps[@]})
      ts_deploy+=(${frontendApps[@]})
      ts_link=true
      ;;

    "--deploy="* | "-d="*)
      #DOC: Will add the provided App to the deploy list

      ts_deploy+=($(regexParam "--deploy|-d" "${paramValue}"))
      ts_link=true
      ;;

    "--deploy-backend" | "-db")
      #DOC: Will add the app-backend to the deploy list

      ts_deploy+=(app-backend)
      ts_link=true
      ;;

    "--deploy-frontend" | "-df")
      #DOC: Will add the app-frontend to the deploy list

      ts_deploy+=(app-frontend)
      ts_link=true
      ;;

    "--set-version="* | "-sv="*)
      #DOC: Set application version before deploy
      #PARAM=x.y.z

      appVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      ts_link=true
      ts_compile=true
      ts_lint=true
      ;;

      #        ==== OTHER ====

    "--no-git")
      noGit=true
      ;;

    "--debug-transpiler")
      CONST_Debug=true
      setDebugLog true
      ts_debug=true
      ((ts_LogLevel > LOG_LEVEL__DEBUG)) && ts_LogLevel=${LOG_LEVEL__DEBUG}
      ;;

    "--debug")
      #DOC: Will print the parameters the script is running with
      ts_debug=true
      ((ts_LogLevel > LOG_LEVEL__DEBUG)) && ts_LogLevel=${LOG_LEVEL__DEBUG}

      ;;

    "--debugger")
      #DOC: Will stop at break points
      enableDebugger
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
      ts_runTests=
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

      local p=${promoteThunderstormVersion}
      [[ "${p}" != "patch" ]] && [[ "${p}" != "minor" ]] && [[ "${p}" != "major" ]] && throwError "Bad version type: ${promoteThunderstormVersion}" 2

      ts_link=true
      ts_clean=true
      ts_compile=true
      ts_publish=true
      ts_lint=true
      ;;

    "--quick-publish" | "-qp")
      #DOC: Will publish thunderstorm without link clean lint and compile
      #WARNING: ONLY used for publishing Thunderstorm!!
      #WARNING: Use only if you REALLY understand the lifecycle of the project and script!!

      ts_link=
      ts_clean=
      ts_compile=
      ts_lint=
      ;;

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done

  printDebugParams "${ts_debug}" "${params[@]}"
  setLogLevel "${ts_LogLevel}"
}
