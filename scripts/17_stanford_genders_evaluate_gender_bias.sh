#!/bin/bash

FOLDER=stanford_genders
TARGET_LANG=lv

cd ..

# Get WinoMT genders file
mkdir data/wino_mt/$FOLDER

python scripts/python/wino_mt_genders.py \
  --wino_mt mt_gender/data/aggregates/en.txt \
  --tokenized_sentences data/wino_mt/en.txt \
  >data/wino_mt/en.genders.txt

python scripts/python/genders_bpe.py \
  --genders data/wino_mt/en.genders.txt \
  --bpe_sentences data/wino_mt/en.BPE.txt \
  >data/wino_mt/en.genders.BPE.txt

# Translate gender bias dataset
python -m sockeye.translate -m models/nmt_$FOLDER \
  --input data/wino_mt/en.BPE.txt \
  --input-factors data/wino_mt/en.genders.BPE.txt |
  sed -r 's/@@( |$)//g' >data/wino_mt/$FOLDER/lv.txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/$FOLDER/lv.txt | sed 's/|/ ||| /g' >data/wino_mt/$FOLDER/en-lv.txt
mkdir mt_gender/translations/$FOLDER
cp data/wino_mt/$FOLDER/en-lv.txt mt_gender/translations/$FOLDER/en-lv.txt

# Get genders
python scripts/python/generate_genders.py --lang $TARGET_LANG --source data/wino_mt/$FOLDER/lv.txt \
  --output data/wino_mt/$FOLDER/lv.genders.txt

# Run evaluation
(
  cd mt_gender/src
  export FAST_ALIGN_BASE="../../tools/fast_align"

  for file in "" "_anti" "_pro"; do
    sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en$file.txt lv $FOLDER ../../data/wino_mt/$FOLDER/lv.genders.txt \
      >../../evaluation_logs/$FOLDER/gender_bias$file.txt
  done
)
