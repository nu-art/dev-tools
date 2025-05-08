#!/bin/bash

# ==================================================
# Generate a self-signed SSL certificate with SAN support
# For local development (supports wildcard subdomains like *.localhost)
#
# Author: Based on original work by Adam van der Kruk aka TacB0sS
# Updated: 2025
# License: Apache 2.0
# ==================================================

# Default values
DOMAIN="localhost"
OUTPUT_DIR="."
POSTFIX=""
ORG_NAME="DEV"
SUBDOMAINS=()

# Parse arguments
for arg in "$@"; do
  case $arg in
    --output=*)
      OUTPUT_DIR="${arg#*=}"
      ;;
    --postfix=*)
      POSTFIX="-${arg#*=}"
      ;;
    --domain=*)
      DOMAIN="${arg#*=}"
      ;;
    --sub-domain=*)
      SUBDOMAINS+=("${arg#*=}")
      ;;
    --org-name=*)
      ORG_NAME="${arg#*=}"
      ;;
    *)
      echo "❌ Unknown parameter: ${arg}"
      exit 1
      ;;
  esac
done

# Ensure output directory exists
mkdir -p "${OUTPUT_DIR}"

# Filenames
KEY_FILE="${OUTPUT_DIR}/server-key${POSTFIX}.pem"
CERT_FILE="${OUTPUT_DIR}/server-cert${POSTFIX}.pem"
CONFIG_FILE="${OUTPUT_DIR}/openssl-${DOMAIN}${POSTFIX}.cnf"

# Generate temporary OpenSSL config with SAN support
cat > "${CONFIG_FILE}" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = US
ST = ${ORG_NAME}
L = ${ORG_NAME}
O = ${ORG_NAME}
OU = ${ORG_NAME}
CN = ${ORG_NAME}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.${DOMAIN}
DNS.2 = ${DOMAIN}
EOF

# Add subdomains to the SAN section
DNS_INDEX=3
for SUBDOMAIN in "${SUBDOMAINS[@]}"; do
  echo "DNS.${DNS_INDEX} = ${SUBDOMAIN}.${DOMAIN}" >> "${CONFIG_FILE}"
  ((DNS_INDEX++))
done

# Generate private key and certificate
openssl req \
  -x509 \
  -nodes \
  -days 825 \
  -newkey rsa:2048 \
  -keyout "${KEY_FILE}" \
  -out "${CERT_FILE}" \
  -config "${CONFIG_FILE}" \
  -extensions req_ext

# Cleanup
rm "${CONFIG_FILE}"

echo "✅ Certificate created:"
echo "   Key:  ${KEY_FILE}"
echo "   Cert: ${CERT_FILE}"