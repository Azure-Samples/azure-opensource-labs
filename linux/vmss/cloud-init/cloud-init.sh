#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

[[ -z "${HELLO:-}" ]] && HELLO='...'
echo "HELLO: ${HELLO}" | tee output.txt

