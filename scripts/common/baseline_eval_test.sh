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

# Prepare test data
(
  operations=30000
  threshold=50

  cd data/"$LANG"

  # Prepare test src
  sacrebleu -t $WMT_SET -l en-${LANG:0:2} --echo src >$VALIDATION.raw.en
  "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en  <"$VALIDATION".raw.en |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l en |
    "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model $PROJECT_ROOT/models/truecase-model.en >"$VALIDATION".tc.en
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold <"$VALIDATION".tc.en >"$VALIDATION".tc.BPE.en


  # Prepare test reference
  sacrebleu -t $WMT_SET -l en-${LANG:0:2} --echo ref > $VALIDATION.raw.$LANG
  "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ${LANG:0:2}  <$VALIDATION.raw.$LANG |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l ${LANG:0:2} |
    "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model $PROJECT_ROOT/models/truecase-model.${LANG:0:2} >"$VALIDATION".tc.$LANG
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab."$LANG" --vocabulary-threshold $threshold <"$VALIDATION".tc."$LANG" >"$VALIDATION".tc.BPE."$LANG"
)



python -m sockeye.translate \
  -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
  --input data/$LANG/"$VALIDATION".tc.BPE.en \
  --device-ids $DEVICE_IDS > data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG"

sed -r 's/@@( |$)//g' < data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG" >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG"

# detruecase, detkoenize
cat data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG" |
  perl "$TOOLS"/moses-scripts/scripts/recaser/detruecase.perl |
  perl "$TOOLS"/moses-scripts/scripts/tokenizer/detokenizer.perl -l "${LANG:0:2}" >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.detok."$LANG"

sacrebleu data/"$LANG"/$WMT_SET.normal.ref  <data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.detok."$LANG" >evaluation_logs/"$LANG"/"$EXPERIMENT"/sacrebleu.txt
