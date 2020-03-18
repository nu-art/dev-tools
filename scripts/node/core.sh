#!/bin/bash

function verifyNpmPackagesInstalledGlobally() {
  local package=${1}
  local minVersion=${2}
  local foundVersion="$(getNpmPackageVersion "${package}")"

  [[ "${code}" != "0" ]] && foundVersion=
  [[ "${foundVersion}" == "${minVersion}" ]] && return 0

  logWarning "Found wrong version '${foundVersion}' of '${package}...'"
  logInfo "Installing required package version: ${package}@${minVersion}"
  npm i -g "${package}@${minVersion}"
  return 1
}

function assertNodePackageInstalled() {
  local package=${1}
  verifyNpmPackageInstalledGlobally "${package}"
}

function printNpmPackageVersion() {
  local package=${1}
  logInfo "${package}: $(getNpmPackageVersion "${package}")"
}

function getNpmPackageVersion() {
  local package=${1}

  zevel=$(npm list -g "${package}" | grep "${package}" 2>&1)
  local code=$?
  [[ "${code}" != "0" ]] && echo "N/A" && return 1

  local output="${zevel}"
  local foundVersion=$(echo "${output}" | tail -1 | sed -E "s/.*${package}@(.*)/\1/")
  echo "${foundVersion}"
  return 0
}
