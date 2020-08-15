#!/bin/bash
set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
TOOLS=$PROJECT_ROOT/tools
cd "$PROJECT_ROOT"

LANG=$1
VALIDATION=$2
DEVICE_IDS=$3
EXPERIMENT=base
threshold=50

# Translate dev
mkdir -p data/dev_translations/"$LANG"/"$EXPERIMENT"
mkdir -p evaluation_logs/"$LANG"/"$EXPERIMENT"

(
  cd data/"$LANG"

  if [[ ! -f "$VALIDATION".tc.BPE.en ]]; then
    for lang in en $LANG; do
      side="src"
      if [ $lang = $LANG ]; then
        side="ref"
      fi
      lang_code=${lang:0:2}
      "$TOOLS"/moses-scripts/scripts/generic/input-from-sgm.perl <"$VALIDATION"-en${LANG:0:2}-$side.$lang_code.sgm |
        "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang_code |
        "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang_code |
        "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model $PROJECT_ROOT/models/truecase-model.$lang_code \
          >"$VALIDATION".tc.$lang

      subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.$lang --vocabulary-threshold $threshold <$VALIDATION.tc.$lang >$VALIDATION.tc.BPE.$lang
    done
  fi
)

python -m sockeye.translate -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
  --device-ids $DEVICE_IDS <data/"$LANG"/"$VALIDATION".tc.BPE.en >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG"
sed -r 's/@@( |$)//g' <data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc.BPE."$LANG" >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG"

# Run bleu against reference translaiton
python -m sockeye.evaluate \
  --references data/"$LANG"/"$VALIDATION".tc."$LANG" \
  --hypotheses data/dev_translations/"$LANG"/"$EXPERIMENT"/"$VALIDATION".tc."$LANG" \
  --metrics bleu \
  >evaluation_logs/"$LANG"/"$EXPERIMENT"/bleu_test.txt
