#!/bin/bash
set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
TOOLS=$PROJECT_ROOT/tools
cd "$PROJECT_ROOT"

LANG=$1
VALIDATION=$2
DEVICE_IDS="$3"
WMT_SET=$4
EXPERIMENT=base

mkdir -p data/dev_translations/"$LANG"/"$EXPERIMENT"
mkdir -p evaluation_logs/"$LANG"/"$EXPERIMENT"

(
  cd data/"$LANG"

  # Prepare reference
  sacrebleu -t $WMT_SET -l en-${LANG:0:2} --echo ref > $WMT_SET.ref
  cat $WMT_SET.ref | perl "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ${LANG:0:2} > $WMT_SET.normal.ref
)


python -m sockeye.translate \
  -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
  --input data/$LANG/"$VALIDATION".tc.BPE.en \
  --device-ids $DEVICE_IDS > data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG"

sed -r 's/@@( |$)//g' < data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG" >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG"

cat data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG" | perl "$TOOLS"/moses-scripts/scripts/recaser/detruecase.perl | perl "$TOOLS"/moses-scripts/scripts/tokenizer/detokenizer.perl -l ${LANG:0:2} |
  sacrebleu data/"$LANG"/$WMT_SET.normal.ref > evaluation_logs/"$LANG"/"$EXPERIMENT"/bleu_test.txt
