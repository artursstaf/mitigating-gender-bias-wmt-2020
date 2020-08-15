#!/bin/bash
set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

LANG="$1"
EXPERIMENT="$2"
DEVICE_IDS="$3"
threshold=50

rm -f tmp*

# Takes stdin
python "$PROJECT_ROOT"/scripts/python/seperate_inline_genders.py tmp_txt tmp_genders

subword-nmt <tmp_txt apply-bpe -c "$PROJECT_ROOT"/data/"$LANG"/bpe.codes --vocabulary "$PROJECT_ROOT"/data/"$LANG"/bpe.vocab.en --vocabulary-threshold $threshold >tmp_txt.BPE
python "$PROJECT_ROOT"/scripts/python/genders_bpe.py --genders tmp_genders --bpe_sentences tmp_txt.BPE >tmp_genders.BPE
python -m sockeye.translate --beam-size 50 --input tmp_txt.BPE --input-factors tmp_genders.BPE -m "$PROJECT_ROOT"/models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" --device-ids $DEVICE_IDS | sed -r 's/@@( |$)//g'

rm -f tmp*
