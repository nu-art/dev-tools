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

installAndroidSDK() {
    sudo mkdir /var/lib/jenkins/android-sdk
    cd /var/lib/jenkins/android-sdk

    logInfo "Resolving latest Android tools SDK..."
    local latestLinuxSDK=`curl -s "https://developer.android.com/studio#downloads" | grep sdk-tools-linux-[0-9] | head -1 | sed -E "s/.*(sdk-tools-linux-.*.zip).*/\1/"`
    throwError "Error resolving latest Android tools SDK" $?

    if [[ ! "${latestLinuxSDK}" ]]; then
        throwError "Could not find latest Android tools SDK"
    fi

    logInfo "Downloading Android tools SDK..."
    sudo wget https://dl.google.com/android/repository/${latestLinuxSDK}
    throwError "Could not find latest Android tools SDK" $?

    sudo mv ${latestLinuxSDK} sdk-tools-linux.zip

    logInfo "Unzip Android tools SDK..."
    sudo unzip sdk-tools-linux.zip
    throwError "Could not unzip Android SDK" $?

    logInfo "Deleting sdk zip file"
    sudo rm sdk-tools-linux.zip
    throwError "Could delete zip file" $?

    logInfo "Allow permissions to jenkins"
    sudo chown -R jenkins:jenkins /var/lib/jenkins/android-sdk
}

setupAndroidEnvironmentVariables() {
    if [[ ! `cat /etc/environment | grep USE_SDK_WRAPPER` ]]; then
        echo 'USE_SDK_WRAPPER=true' | sudo tee --append /etc/environment > /dev/null
    fi

    if [[ ! `cat /etc/environment | grep ANDROID_HOME` ]]; then
        echo 'ANDROID_HOME=/var/lib/jenkins/android-sdk' | sudo tee --append /etc/environment > /dev/null
    fi

    if [[ ! `cat /etc/environment | grep ANDROID_NDK_HOME` ]]; then
        echo 'ANDROID_NDK_HOME=/var/lib/jenkins/android-sdk/ndk-bundle' | sudo tee --append /etc/environment > /dev/null
    fi
}
