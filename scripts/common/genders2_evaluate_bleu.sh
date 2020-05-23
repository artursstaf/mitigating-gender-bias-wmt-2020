#!/bin/bash
set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
cd "$PROJECT_ROOT"

LANG=$1
EXPERIMENT=$2
VALIDATION=$3
DEVICE_IDS=$4

mkdir -p data/dev_translations/"$LANG"/"$EXPERIMENT"
mkdir -p evaluation_logs/"$LANG"/"$EXPERIMENT"

# Generate random genders
(
  cd data/"$LANG"/"$EXPERIMENT"
  python ../../../scripts/python/random_genders.py --genders "$VALIDATION".tc.en >g.tmp
  python ../../../scripts/python/genders_bpe.py --genders g.tmp --bpe_sentences "$VALIDATION".tc.BPE.en >"$VALIDATION".r-genders.BPE.en
  rm g.tmp
)

for type in "true " "unkown u-" "random r-"; do
  set -- $type

  python -m sockeye.translate \
    -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
    --input-factors data/"$LANG"/"$EXPERIMENT"/"$VALIDATION"."$2"genders.BPE.en \
    --input data/$LANG/"$VALIDATION".tc.BPE.en \
    --device-ids $DEVICE_IDS |
    sed -r 's/@@( |$)//g' >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc."$LANG"

  python -m sockeye.evaluate \
    --references data/"$LANG"/"$VALIDATION".tc."$LANG" \
    --hypotheses data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc."$LANG" \
    --metrics bleu \
    >evaluation_logs/"$LANG"/"$EXPERIMENT"/bleu_"$1".txt
done
