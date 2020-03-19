#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

CHUNK_SIZE="$1"
DEVICE_IDS="$2"

bash "$PROJECT_ROOT"/scripts/common/genders2_pre-process.sh lt genders2 newsdev2019 corpus "$CHUNK_SIZE" "$DEVICE_IDS"
