#!/bin/bash

cd ..

# Get WinoMT genders file
mkdir data/wino_mt/genders2

python scripts/python/wino_mt_genders.py \
    --wino_mt mt_gender/data/aggregates/en.txt \
    --tokenized_sentences data/wino_mt/en.txt \
    >data/wino_mt/en.genders.txt

python scripts/python/genders_bpe.py \
    --genders data/wino_mt/en.genders.txt \
    --bpe_sentences data/wino_mt/en.BPE.txt \
    >data/wino_mt/en.genders.BPE.txt

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

for file in "" "_anti" "_pro"; do
    sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en$file.txt lv genders2 ../../data/wino_mt/genders2/lv.genders.txt \
        >../../evaluation_logs/genders2/gender_bias$file.txt
done

cd ../..
