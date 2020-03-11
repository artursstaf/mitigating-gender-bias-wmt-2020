#!/bin/bash

EXPERIMENT=genders2
LANG=ru

cd ../../

# Get WinoMT genders file
mkdir data/wino_mt/$LANG/$EXPERIMENT

# Translate gender bias dataset
python -m sockeye.translate -m models/$LANG/nmt_"$LANG"_$EXPERIMENT \
  --input data/wino_mt/en.BPE.txt \
  --input-factors data/wino_mt/en.genders.BPE.txt |
  sed -r 's/@@( |$)//g' >data/wino_mt/$LANG/$EXPERIMENT/$LANG.txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/$LANG/$EXPERIMENT/$LANG.txt | sed 's/|/ ||| /g' >data/wino_mt/$LANG/$EXPERIMENT/en-$LANG.txt
mkdir mt_gender/translations/"$LANG"_$EXPERIMENT
cp data/wino_mt/$LANG/$EXPERIMENT/en-$LANG.txt mt_gender/translations/"$LANG"_$EXPERIMENT/en-$LANG.txt

# Get genders
python scripts/python/generate_genders.py --lang $LANG --source data/wino_mt/$LANG/$EXPERIMENT/$LANG.txt \
  --output data/wino_mt/$LANG/$EXPERIMENT/$LANG.genders.txt

# Run evaluation
(
  cd mt_gender/src
  export FAST_ALIGN_BASE="../../tools/fast_align"

  for file in "" "_anti" "_pro"; do
    sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en$file.txt $LANG "$LANG"_$EXPERIMENT ../../data/wino_mt/$LANG/$EXPERIMENT/$LANG.genders.txt \
      >../../evaluation_logs/$LANG/$EXPERIMENT/gender_bias$file.txt
  done
)

