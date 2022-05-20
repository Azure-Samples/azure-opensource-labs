#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y docker.io

[[ -z "${HELLO:-}" ]] && HELLO='...'
echo "HELLO: ${HELLO}" | tee output.txt

