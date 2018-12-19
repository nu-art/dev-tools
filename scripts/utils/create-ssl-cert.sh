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
outputFolder=${1}

if [ "${outputFolder}" == "" ]; then
 outputFolder="."
fi

if [ ! -d "${outputFolder}" ]; then
  mkdir "${outputFolder}"
fi

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout "${outputFolder}/server-temp.pem" \
    -new \
    -out "${outputFolder}/server-cert.pem" \
    -subj /CN=localhost \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /System/Library/OpenSSL/openssl.cnf \
        <(printf '[SAN]\nsubjectAltName=DNS:localhost')) \
    -sha256 \
    -days 3650

openssl rsa -in "${outputFolder}/server-temp.pem" -out "${outputFolder}/server-key.pem"
