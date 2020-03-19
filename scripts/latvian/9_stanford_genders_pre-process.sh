#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

CHUNK_SIZE="$1"
DEVICE_IDS="$2"

bash "$PROJECT_ROOT"/scripts/common/genders2_pre-process.sh lv stanford_genders newsdev2017 corpus "$CHUNK_SIZE" "$DEVICE_IDS"
