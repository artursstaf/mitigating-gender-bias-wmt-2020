#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
cd "$PROJECT_ROOT"

LANG=$1
VALIDATION=$2
DEVICE_IDS=$3
EXPERIMENT=base

# Translate dev
mkdir -p data/dev_translations/"$LANG"/"$EXPERIMENT"
mkdir -p evaluation_logs/"$LANG"/"$EXPERIMENT"

python -m sockeye.translate -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
  --device-ids $DEVICE_IDS <data/"$LANG"/"$VALIDATION".tc.BPE.en |
  sed -r 's/@@( |$)//g' >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG"

# Run bleu against reference translaiton
python -m sockeye.evaluate \
  --references data/"$LANG"/"$VALIDATION".tc."$LANG" \
  --hypotheses data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG" \
  --metrics bleu \
  >evaluation_logs/"$LANG"/"$EXPERIMENT"/bleu.txt
