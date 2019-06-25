#
#  This file is a part of nu-art projects development tools,
#  it has a set of bash and gradle scripts, and the default
#  settings for Android Studio and IntelliJ.
#
#     Copyright (C) 2017  Adam van der Kruk aka TacB0sS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#          You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

#!/bin/bash
source ${BASH_SOURCE%/*}/../android/_source.sh

function executeCommand() {
    local command=${1}
    local message=${2}
    if [[ ! "${message}" ]]; then message="Running: ${1}"; fi
    logInfo "${message}"
    eval "${command}"
    throwError "${message}"
}

setupSwap=true
setupJenkins=true
setupJava=
javaUrl=

params=(setupSwap setupJenkins setupJava javaUrl)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--java-url="*)
                javaUrl=`echo "${paramValue}" | sed -E "s/--java-url=(.*)/\1/"`
                setupJava=true
            ;;

            "--no-swap")
                setupSwap=
            ;;

            "--no-jenkins")
                setupJenkins=
            ;;

        esac
    done
}

extractParams "$@"

signature "Jenkins Setup"
printCommand "$@"
printDebugParams "${params[@]}"

executeCommand "sudo apt-get update"

# Installing packages
executeCommand "sudo apt-get install -y unzip" "Installing unzip"
executeCommand "sudo apt-get install -y zip" "Installing zip"

if [[ "${setupSwap}" ]]; then
    # Set 16 gb swap
    executeCommand "sudo fallocate -l 16G /swapfile" "Setup 16gb swapfile"
    executeCommand "sudo chmod 600 /swapfile" "chmod 600 for swapfile"
    executeCommand "sudo mkswap /swapfile" "Make swap to swapfile"
    executeCommand "sudo swapon /swapfile" "Enable swap"
fi

# Install Groovy & Gradle
executeCommand "curl -s \"https://get.sdkman.io\" | bash" "Downloading sdkman"
executeCommand "source /home/ubuntu/.sdkman/bin/sdkman-init.sh" "Source sdkman"
executeCommand "sdk install groovy" "Installing Groovy"
executeCommand "sdk install gradle" "Installing Gradle"

# Installing Java8
if [[ "${setupJava}" ]]; then
    javaFileName="java-jdk8.tar.gz"
    javaOutputFolder="jdk1.8.0"
    javaSystemPath="/usr/lib/jvm"

    executeCommand "wget -O ${javaFileName} ${javaUrl}" "Downloading Java 8 JDK"
    executeCommand "mkdir ./${javaOutputFolder}" "Creating java 8 output folder"
    executeCommand "tar -xvf ${javaFileName} -C ./${javaOutputFolder} --strip-components=1" "Extracting Java 8 JDK"
    executeCommand "sudo mkdir -p ${javaSystemPath}" "Creating system jvm folder"
    executeCommand "sudo mv ./${javaOutputFolder} ${javaSystemPath}/" "Moving jdk to jvm folder"
    executeCommand "sudo update-alternatives --install \"/usr/bin/java\" \"java\" \"/usr/lib/jvm/jdk1.8.0/bin/java\" 1" "setting default java"
    executeCommand "sudo update-alternatives --install \"/usr/bin/javac\" \"javac\" \"/usr/lib/jvm/jdk1.8.0/bin/javac\" 1" "setting default javac"
    executeCommand "sudo update-alternatives --install \"/usr/bin/javaws\" \"javaws\" \"/usr/lib/jvm/jdk1.8.0/bin/javaws\" 1" "setting default javaws"
    executeCommand "sudo chmod a+x /usr/bin/java" "Set as executable java"
    executeCommand "sudo chmod a+x /usr/bin/javac" "Set as executable javac"
    executeCommand "sudo chmod a+x /usr/bin/javaws" "Set as executable javaws"
fi

# Installing Jenkins
if [[ "${setupJenkins}" ]]; then
    executeCommand "wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -" "Resolving Jenkins - 1"
    executeCommand "echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list" "Resolving Jenkins - 2"

    executeCommand "sudo apt-get update"
    executeCommand "sudo apt-get install -y jenkins" "Install Jenkins"
    executeCommand "sudo systemctl start jenkins" "Start Jenkins"
fi

# Installing Node & npm
executeCommand "curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -" "Install Node & npm"
executeCommand "sudo apt-get install -y nodejs"

# Open ports
executeCommand "sudo ufw allow 8080" "Open port 8080"
executeCommand "sudo ufw allow 22" "Open port 22"
executeCommand "sudo ufw status" "Status of ufw"

# Install Android SDK
executeCommand "installAndroidSDK" "Install Android SDK"
executeCommand "setupAndroidEnvironmentVariables" "Setup Android SDK and NDK Environment"


executeCommand "sudo cat /var/lib/jenkins/secrets/initialAdminPassword" "Displaying Jenkins Admin Password"

#executeCommand "sudo ufw enable" "Enable ufw"
#executeCommand "sudo systemctl status jenkins" "Check Jenkins Status"

