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

executeCommand "sudo apt-get update"
executeCommand "sudo apt-get install unzip" "Install UnZip"

# Set 16 gb swap

executeCommand "echo \"/swapfile       none    swap    sw      0       0\" | sudo tee /etc/fstab" "Make sure swap would last after reboot"
executeCommand "sudo fallocate -l 16G /swapfile" "Setup 16gb swapfile"
executeCommand "sudo chmod 600 /swapfile" "chmod 600 for swapfile"
executeCommand "sudo mkswap /swapfile" "Make swap to swapfile"
executeCommand "sudo swapon /swapfile" "Enable swap"

# Install Groovy & Gradle
executeCommand "curl -s \"https://get.sdkman.io\" | bash" "Downloading sdkman"
executeCommand "source /home/ubuntu/.sdkman/bin/sdkman-init.sh" "Source sdkman"
executeCommand "sdk install groovy" "Installing Groovy"
executeCommand "sdk install gradle" "Installing Gradle"

# New repos for apt-get
executeCommand "sudo add-apt-repository -y ppa:webupd8team/java" "Resolving Java repo"
executeCommand "wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -" "Resolving Jenkins - 1"
executeCommand "echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list" "Resolving Jenkins - 2"

executeCommand "sudo apt-get update"

# Installing packages
executeCommand "sudo apt-get install -y unzip" "Installing unzip"
executeCommand "sudo apt-get install -y zip" "Installing zip"

# Installing Java8
executeCommand "sudo apt-get install -y oracle-java8-installer" "Install Java8"
executeCommand "echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections" "Accept Java8 agreement"

# Installing Jenkins
executeCommand "sudo apt-get install -y jenkins" "Install Jenkins"
executeCommand "sudo systemctl start jenkins" "Start Jenkins"

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

