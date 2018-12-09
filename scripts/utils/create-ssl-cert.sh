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
