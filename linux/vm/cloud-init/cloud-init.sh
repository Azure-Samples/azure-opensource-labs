#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

cd /home/azureuser/
[[ -z "${HELLO:-}" ]] && HELLO='HELLO'
echo "${HELLO} : $(date)" | tee output.txt
