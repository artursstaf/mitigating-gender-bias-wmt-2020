#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
cd "$PROJECT_ROOT"

LANG=$1
EXPERIMENT=$2
DEVICE_IDS=$3

# Pre-process gender bias dataset
mkdir -p data/wino_mt/"$LANG"/"$EXPERIMENT"

cut -d'	' -f3 <mt_gender/data/aggregates/en.txt >data/wino_mt/en.raw.txt

tools/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en <data/wino_mt/en.raw.txt |
  tools/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l en |
  tools/moses-scripts/scripts/recaser/truecase.perl -model models/truecase-model.en >data/wino_mt/en.txt

subword-nmt apply-bpe -c data/"$LANG"/bpe.codes --vocabulary data/"$LANG"/bpe.vocab.en --vocabulary-threshold 50 <data/wino_mt/en.txt >data/wino_mt/"$LANG"/"$EXPERIMENT"/en.BPE.txt

# Get WinoMT genders file
python scripts/python/wino_mt_genders.py \
--wino_mt mt_gender/data/aggregates/en.txt \
--tokenized_sentences data/wino_mt/en.txt \
>data/wino_mt/en.genders.txt

python scripts/python/genders_bpe.py \
--genders data/wino_mt/en.genders.txt \
--bpe_sentences data/wino_mt/$LANG/$EXPERIMENT/en.BPE.txt \
>data/wino_mt/$LANG/$EXPERIMENT/en.genders.BPE.txt

# Translate gender bias dataset
python -m sockeye.translate -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
--input data/wino_mt/"$LANG"/"$EXPERIMENT"/en.BPE.txt \
--input-factors data/wino_mt/"$LANG"/"$EXPERIMENT"/en.genders.BPE.txt \
--device-ids $DEVICE_IDS |
  sed -r 's/@@( |$)//g' >data/wino_mt/"$LANG"/"$EXPERIMENT"/"$LANG".txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/"$LANG"/"$EXPERIMENT"/"$LANG".txt | sed 's/|/ ||| /g' >data/wino_mt/"$LANG"/"$EXPERIMENT"/en-"$LANG".txt
mkdir mt_gender/translations/"$LANG"_"$EXPERIMENT"
cp data/wino_mt/"$LANG"/"$EXPERIMENT"/en-"$LANG".txt mt_gender/translations/"$LANG"_"$EXPERIMENT"/en-"$LANG".txt

# Get translated genders
export CUDA_VISIBLE_DEVICES="$DEVICE_IDS"
python scripts/python/generate_genders.py --lang "${LANG:0:2}" --source data/wino_mt/"$LANG"/"$EXPERIMENT"/"$LANG".txt \
--output data/wino_mt/"$LANG"/"$EXPERIMENT"/"$LANG".genders.txt

# Run evaluation
(
  cd mt_gender/src || exit
  export FAST_ALIGN_BASE="../../tools/fast_align"

  for file in "" "_anti" "_pro"; do
    sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en$file.txt "$LANG" "$LANG"_"$EXPERIMENT" ../../data/wino_mt/"$LANG"/"$EXPERIMENT"/"$LANG".genders.txt \
    >../../evaluation_logs/"$LANG"/"$EXPERIMENT"/gender_bias$file.txt
  done
)
