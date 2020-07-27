#!/bin/bash

__debug=
__dependencies=
__clean=
__install=true
__compile=true
__runTests=
__publish=


__generate=()
__launch=()
__deploy=()
__testsToRun=()
__activeLibs=()
__LogLevel=${LOG_LEVEL__INFO}

params=(
  envType
  ThunderstormHome
  printEnv
  testServiceAccount
  __dependencies
  __purge
  __clean
  __install
  __compile
  __watch
  __link
  __linkThunderstorm
  __lint
  __runTests
  __publish
  "__generate[@]"
  "__launch[@]"
  "__deploy[@]"
  "__activeLibs[@]"
  "__testsToRun[@]"
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
      #￿￿￿￿DOC: This help menu

      printHelp "${BASH_SOURCE%/*}/params.sh"
      ;;

    "--dependencies-tree" | "-dt")
      #DOC: Will print the projects packages dependencie tree into the .trash folder

      __dependencies=true
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
    "--clean" | "-c")
      #DOC: Will delete the output(dist) & test output(dist-test) folders in all project packages

      __clean=true
      ;;

      #        ==== BUILD ====
    "--use-package="* | "-up="*)
      #DOC: Would ONLY run the script in the context of the specified project packages
      #PARAM=project-package-folder

      local lib=$(regexParam "--use-package|-up" "${paramValue}")
      __activeLibs+=("${lib}")
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

      __install=true
      __link=true
      ;;

    "--generate" | "-g")
      __generate+=(${backendApps[@]})
      __generate+=(${frontendApps[@]})
      __link=
      __compile=
      ;;

    "--generate="* | "-g="*)
      #DOC: Will generate sources in the apps if needed
      __generate+=($(regexParam "--generate|-g" "${paramValue}"))
      __link=
      __compile=
      ;;

    "--link" | "-ln")
      #DOC: Would link dependencies between project packages

      __link=true
      ;;

    "--link-only" | "-lo")
      #DOC: Would ONLY link dependencies between project packages

      __link=true
      __compile=
      ;;

    "--no-build" | "-nb")
      #DOC: Skip the build and link steps
      __compile=
      __link=

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

      __link=true
      __linkThunderstorm=true

      local temp=$(regexParam "--thunderstorm-home|-th" "${paramValue}")
      [[ "${temp}" ]] && ThunderstormHome="${temp}"
      ;;

    "--lint")
      #DOC: Run lint on all the project packages
      __lint=true
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
      __watch=true
      __compile=true
      CONST_BuildWatchFile="$(pwd)/.trash/watch.txt"

      ;;

      #        ==== TEST ====
    "--test" | "-t")
      #DOC: Run the tests in all the project packages
      #NOTE: Running this way expecting the "testServiceAccount" variable to be defined gloabally

      [[ ! "${testServiceAccount}" ]] && throwError "MUST specify the path to the testServiceAccount in the .scripts/modules.sh in your project"
      __runTests=true
      ;;

    "--test="* | "-t="*)
      #DOC: Specify tests you want to run
      #PARAM="the label of the test you want to run"

      local testToRun="$(regexParam "--test|-t" "${paramValue}")"
      __testsToRun+=("${testToRun}")
      __runTests=true
      ;;

    "--account="* | "-a="*)
      #DOC: Run the tests in all the project packages
      #PARAM=path-to-firebase-service-account

      testServiceAccount=$(regexParam "--account|-a" "${paramValue}")
      __runTests=true
      ;;

    "--output-test-dir="* | "-otd="*)
      #DOC: Set the tests output dir name/path (default: dist-test)
      #PARAM=path-to-tests-output-folder

      outputTestDir=$(regexParam "--output-test-dir|-otd" "${paramValue}")
      ;;

      #        ==== Apps ====
    "--launch="* | "-l="*)
      #DOC: It will add the provided App to the launch list
      __launch+=($(regexParam "--launch|-l" "${paramValue}"))
      ;;

    "--launch-frontend" | "-lf")
      #DOC: Will add the app-frontend to the launch list
      __launch+=(app-frontend)
      ;;

    "--launch-backend" | "-lb")
      #DOC: Will add the app-backend to the launch list
      __launch+=(app-backend)
      ;;

    "--deploy" | "-d")
      __deploy+=(${backendApps[@]})
      __deploy+=(${frontendApps[@]})
      __link=true
      ;;

    "--deploy="* | "-d="*)
      #DOC: Will add the provided App to the deploy list

      __deploy+=($(regexParam "--deploy|-d" "${paramValue}"))
      __link=true
      ;;

    "--deploy-backend" | "-db")
      #DOC: Will add the app-backend to the deploy list

      __deploy+=(app-backend)
      __link=true
      ;;

    "--deploy-frontend" | "-df")
      #DOC: Will add the app-frontend to the deploy list

      __deploy+=(app-frontend)
      __link=true
      ;;

    "--set-version="* | "-sv="*)
      #DOC: Set application version before deploy
      #PARAM=x.y.z

      appVersion=$(regexParam "--set-version|-sv" "${paramValue}")
      __link=true
      __compile=true
      __lint=true
      ;;

      #        ==== OTHER ====

    "--no-git")
      noGit=true
      ;;

    "--debug")
      #DOC: Will print the parameters the script is running with
      setDebugLog true
      __debug=true
      ((__LogLevel > LOG_LEVEL__DEBUG)) && __LogLevel=${LOG_LEVEL__DEBUG}

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
      __LogLevel=${!logLevelKey}
      [[ ! ${__LogLevel} ]] && __LogLevel=${LOG_LEVEL__INFO}

      ;;

    "--quick-deploy" | "-qd")
      #DOC: Will deploy both frontend & backend, without any other lifecycle action
      #WARNING: Use only if you REALLY understand the lifecycle of the project and script!!

      __lint=
      __compile=
      __runTests=
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

      __link=true
      __clean=true
      __compile=true
      __publish=true
      __lint=true
      ;;

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done

  printDebugParams "${__debug}" "${params[@]}"
  setLogLevel "${__LogLevel}"
}
