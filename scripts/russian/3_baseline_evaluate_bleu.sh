#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

DEVICE_IDS=$1

bash "$PROJECT_ROOT"/scripts/common/baseline_eval_test.sh ru newstest2015 "$DEVICE_IDS" wmt15
