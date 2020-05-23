#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

bash "$PROJECT_ROOT"/scripts/common/baseline_prepare_data.sh lv_imba newsdev2017 train
