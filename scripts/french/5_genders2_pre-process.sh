#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

CHUNK_SIZE="2"
DEVICE_IDS="$1"

bash "$PROJECT_ROOT"/scripts/common/genders2_pre-process.sh fr genders2 develop corpus "$CHUNK_SIZE" "$DEVICE_IDS"
