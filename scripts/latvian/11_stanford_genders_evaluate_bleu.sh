#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

DEVICE_IDS=$1

bash "$PROJECT_ROOT"/scripts/common/genders2_eval_test.sh lv stanford_genders corpus newstest2017 "$DEVICE_IDS" wmt17
