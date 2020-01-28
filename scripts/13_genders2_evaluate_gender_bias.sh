#!/bin/bash

cd ..

# Get WinoMT genders file
mkdir data/wino_mt/genders2

# Translate gender bias dataset
python -m sockeye.translate -m models/nmt_genders2 \
    --input data/wino_mt/en.BPE.txt \
    --input-factors data/wino_mt/en.genders.BPE.txt |
    sed -r 's/@@( |$)//g' >data/wino_mt/genders2/lv.txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/genders2/lv.txt | sed 's/|/ ||| /g' >data/wino_mt/genders2/en-lv.txt
mkdir mt_gender/translations/genders2
cp data/wino_mt/genders2/en-lv.txt mt_gender/translations/genders2/en-lv.txt

# Get genders
cd tools/morph-analysis
./gradlew run --args='../../data/wino_mt/genders2/lv.txt ../../data/wino_mt/genders2/lv.genders.txt'
cd ../../

# Run evaluation
cd mt_gender/src
export FAST_ALIGN_BASE="../../tools/fast_align"

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en.txt lv genders2 ../../data/wino_mt/genders2/lv.genders.txt \
    >../../evaluation_logs/genders2/gender_bias.txt

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en_anti.txt lv genders2 ../../data/wino_mt/genders2/lv.genders.txt \
    >../../evaluation_logs/genders2/gender_bias_anti.txt

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en_pro.txt lv genders2 ../../data/wino_mt/genders2/lv.genders.txt \
    >../../evaluation_logs/genders2/gender_bias_pro.txt

cd ../..
