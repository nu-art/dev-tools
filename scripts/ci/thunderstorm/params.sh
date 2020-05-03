#!/bin/bash

debug=

branch=
gitUrl=
folderName=
versionPromotion=

deploy=
publish=
environment=

params=(debug branch gitUrl folderName environment versionPromotion deploy publish)

extractParams() {
  for paramValue in "${@}"; do
    case "${paramValue}" in
    #        ==== General ====
    "--help" | "-h")
      #￿￿￿￿DOC: This help menu

      printHelp "${BASH_SOURCE%/*}/params.sh"
      ;;

    "--branch="* | "-b="*)
      #￿￿￿￿DOC: which branch to clone

      branch=$(regexParam "--branch|-b" "${paramValue}")
      ;;

    "--gitUrl="* | "-u="*)
      #￿￿￿￿DOC: The project repo to clone from

      gitUrl=$(regexParam "--gitUrl|-u" "${paramValue}")
      ;;

    "--folderName="* | "-f="*)
      #￿￿￿￿DOC: The local folder name the repo will be cloned into

      folderName=$(regexParam "--folderName|-f" "${paramValue}")
      ;;

    "--publish="* | "-p="*)
      #￿￿￿￿DOC: Whether to publish artifacts an which version to promote
      #PARAM=[pathc | minor | major]

      versionPromotion=$(regexParam "--publish|-p" "${paramValue}")
      publish=true
      ;;

    "--deploy" | "-d")
      #￿￿￿￿DOC: Whether to deploy frontend and backend

      deploy=true
      ;;

    "--env=" | "-e=")
      #￿￿￿￿DOC: Which environment to build the project

      environment=$(regexParam "--env|-e" "${paramValue}")
      ;;

    *)
      logWarning "UNKNOWN PARAM: ${paramValue}"
      ;;
    esac
  done

  [[ ! "${branch}" ]] && throwError "Mandatory param is missing: branch" 2
  [[ ! "${gitUrl}" ]] && throwError "Mandatory param is missing: gitUrl" 2
  [[ ! "${folderName}" ]] && throwError "Mandatory param is missing: folderName" 2
  [[ ! "${versionPromotion}" ]] && throwError "Mandatory param is missing: versionPromotion" 2
  [[ ! "${environment}" ]] && throwError "Mandatory param is missing: environment" 2

}
