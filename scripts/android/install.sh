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

installAndroidSDK_JENKINS() {
  sudo mkdir /var/lib/jenkins/android-sdk
  _cd /var/lib/jenkins/android-sdk

  logInfo "Resolving latest Android tools SDK..."
  local latestSDK=$(curl -s "https://developer.android.com/studio#downloads" | grep "commandlinetools-linux-[0-9]" | head -1 | sed -E "s/.*(commandlinetools-linux-.*.zip).*/\1/")
  throwError "Error resolving latest Android tools SDK"

  [[ ! "${latestSDK}" ]] && throwError "Could not find latest Android tools SDK" 2

  logInfo "Downloading Android tools SDK..."
  sudo wget https://dl.google.com/android/repository/"${latestSDK}"
  throwError "Could not find latest Android tools SDK"

  sudo mv "${latestSDK}" sdk-tools-linux.zip

  logInfo "Unzip Android tools SDK..."
  sudo unzip sdk-tools-linux.zip
  throwError "Could not unzip Android SDK"

  logInfo "Deleting sdk zip file"
  sudo rm sdk-tools-linux.zip
  throwError "Could delete zip file"

  logInfo "Allow permissions to jenkins"
  sudo chown -R jenkins:jenkins /var/lib/jenkins/android-sdk
}

installAndroidSDK_MAC() {
  local pathToAndroidHome=${HOME}/Library/Android/sdk
  local sdkZipName=android-sdk.zip
  mkdir -p "${pathToAndroidHome}"
  _pushd "${pathToAndroidHome}"

  logInfo "Resolving latest Android tools SDK..."
  local latestSDK=$(curl -s "https://developer.android.com/studio#downloads" | grep "commandlinetools-mac-[0-9]" | head -1 | sed -E "s/.*(commandlinetools-mac-.*.zip).*/\1/")
  throwError "Error resolving latest Android tools SDK"

  [[ ! "${latestSDK}" ]] && throwError "Could not find latest Android tools SDK" 2

  logInfo "Downloading Android tools SDK..."
  curl https://dl.google.com/android/repository/"${latestSDK}" -o "${sdkZipName}"
  throwError "Could not find latest Android tools SDK"

  logInfo "Unzip Android tools SDK..."
  unzip "${sdkZipName}"
  throwError "Could not unzip Android SDK"

  logInfo "Deleting sdk zip file"
  rm "${sdkZipName}"
  throwError "Could delete zip file"
}

setupAndroidEnvironmentVariables_MAC() {
  local profileFile="${HOME}/.bash_profile"
  if [[ ! $(cat "${profileFile}" | grep ANDROID_HOME) ]]; then
    echo "export ANDROID_HOME=${HOME}/Library/Android/sdk" | tee --append "${profileFile}" > /dev/null
  fi

  if [[ ! $(cat "${profileFile}" | grep ANDROID_NDK_HOME) ]]; then
    echo "export ANDROID_NDK_HOME=${HOME}/Library/Android/sdk/ndk-bundle" | tee --append "${profileFile}" > /dev/null
  fi
}

setupAndroidEnvironmentVariables_JENKINS() {
  if [[ ! $(cat /etc/environment | grep USE_SDK_WRAPPER) ]]; then
    echo 'USE_SDK_WRAPPER=true' | sudo tee --append /etc/environment > /dev/null
  fi

  if [[ ! $(cat /etc/environment | grep ANDROID_HOME) ]]; then
    echo 'ANDROID_HOME=/var/lib/jenkins/android-sdk' | sudo tee --append /etc/environment > /dev/null
  fi

  if [[ ! $(cat /etc/environment | grep ANDROID_NDK_HOME) ]]; then
    echo 'ANDROID_NDK_HOME=/var/lib/jenkins/android-sdk/ndk-bundle' | sudo tee --append /etc/environment > /dev/null
  fi
}

source dev-tools/scripts/_core-tools/_source.sh
setupAndroidEnvironmentVariables_MAC
