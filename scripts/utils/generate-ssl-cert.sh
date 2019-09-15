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

for (( lastParam=1; lastParam<=$#; lastParam+=1 )); do
    paramValue="${!lastParam}"
    case ${paramValue} in
        "--output="*)
            outputFolder=`regexParam "--output" "${paramValue}"`
        ;;

        "--postfix="*)
            postfix=`regexParam "--postfix" "${paramValue}"`
            postfix="-${postfix}"
        ;;

        "--domain="*)
            domain=`regexParam "--domain" "${paramValue}"`
        ;;

        "*")
            echo "UNKNOWN PARAM: ${paramValue}"
            exit 1
        ;;
    esac
done

if [[ ! "${domain}" ]]; then
  domain="localhost"
fi

if [[ ! "${outputFolder}" ]]; then
  outputFolder="."
fi

if [[ ! -d "${outputFolder}" ]]; then
  mkdir "${outputFolder}"
fi

tempFile="${outputFolder}/server-temp${postfix}.pem"
certificateFile="${outputFolder}/server-cert${postfix}.pem"
keyFile="${outputFolder}/server-key${postfix}.pem"

openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout "${tempFile}" \
    -new \
    -out "${certificateFile}" \
    -subj /CN=${domain} \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /System/Library/OpenSSL/openssl.cnf \
        <(printf "[SAN]\nsubjectAltName=DNS:${domain}")) \
    -sha256 \
    -days 3650

openssl rsa -in "${tempFile}" -out "${keyFile}"
