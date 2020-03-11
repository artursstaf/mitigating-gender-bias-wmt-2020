#!/bin/bash

EXPERIMENT=stanford_genders
LANG=lv

cd ..

# Get WinoMT genders file
mkdir data/wino_mt/$EXPERIMENT

python scripts/python/wino_mt_genders.py \
  --wino_mt mt_gender/data/aggregates/en.txt \
  --tokenized_sentences data/wino_mt/en.txt \
  >data/wino_mt/en.genders.txt

python scripts/python/genders_bpe.py \
  --genders data/wino_mt/en.genders.txt \
  --bpe_sentences data/wino_mt/en.BPE.txt \
  >data/wino_mt/en.genders.BPE.txt

# Translate gender bias dataset
python -m sockeye.translate -m models/nmt_$EXPERIMENT \
  --input data/wino_mt/en.BPE.txt \
  --input-factors data/wino_mt/en.genders.BPE.txt |
  sed -r 's/@@( |$)//g' >data/wino_mt/$EXPERIMENT/$LANG.txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/$EXPERIMENT/$LANG.txt | sed 's/|/ ||| /g' >data/wino_mt/$EXPERIMENT/en-$LANG.txt
mkdir mt_gender/translations/$EXPERIMENT
cp data/wino_mt/$EXPERIMENT/en-$LANG.txt mt_gender/translations/$EXPERIMENT/en-$LANG.txt

# Get genders
python scripts/python/generate_genders.py --lang $LANG --source data/wino_mt/$EXPERIMENT/$LANG.txt \
  --output data/wino_mt/$EXPERIMENT/$LANG.genders.txt

# Run evaluation
(
  cd mt_gender/src
  export FAST_ALIGN_BASE="../../tools/fast_align"

  for file in "" "_anti" "_pro"; do
    sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en$file.txt $LANG $EXPERIMENT ../../data/wino_mt/$EXPERIMENT/$LANG.genders.txt \
      >../../evaluation_logs/$EXPERIMENT/gender_bias$file.txt
  done
)
