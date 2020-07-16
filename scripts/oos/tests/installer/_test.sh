#!/bin/bash

source "${BASH_SOURCE%/*}/../../core/transpiler.sh"

CONST_Debug=true
addTranspilerClassPath "${BASH_SOURCE%/*}/../../utils"

new InstallerDMG Docker
new InstallerDMG Spectacle


Docker.label = "Docker"
Docker.outputFile = "docker.dmg"
Docker.downloadUrl = "https://download.docker.com/mac/stable/Docker.dmg"

Spectacle.label = "Spectacle"
Spectacle.inZipFile = "Spectacle.app"
Spectacle.requiresMount =
Spectacle.outputFile = "Spectacle.zip"
Spectacle.downloadUrl = "https://s3.amazonaws.com/spectacle/downloads/Spectacle+1.2.zip"

Spectacle.install
Docker.install
