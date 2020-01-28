#!/bin/bash

cd ..

mkdir data/wino_mt

# Pre-process gender bias dataset
cut -d'	' -f3 <mt_gender/data/aggregates/en.txt >data/wino_mt/en.raw.txt

tools/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l en <data/wino_mt/en.raw.txt |
    tools/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l en |
    tools/moses-scripts/scripts/recaser/truecase.perl -model models/truecase-model.en >data/wino_mt/en.txt

subword-nmt apply-bpe -c data/bpe.codes --vocabulary data/bpe.vocab.en --vocabulary-threshold 50 <data/wino_mt/en.txt >data/wino_mt/en.BPE.txt

# Translate gender bias dataset
mkdir data/wino_mt/base
python -m sockeye.translate -m models/nmt_base <data/wino_mt/en.BPE.txt | sed -r 's/@@( |$)//g' >data/wino_mt/base/lv.txt

# Combine into format that is expected by mt_gender scripts
paste -d "|" data/wino_mt/en.raw.txt data/wino_mt/base/lv.txt | sed 's/|/ ||| /g' >data/wino_mt/base/en-lv.txt
mkdir mt_gender/translations/base
cp data/wino_mt/base/en-lv.txt mt_gender/translations/base/en-lv.txt

# Get genders
cd tools/morph-analysis
./gradlew run --args='../../data/wino_mt/base/lv.txt ../../data/wino_mt/base/lv.genders.txt'
cd ../../

# Run evaluation
cd mt_gender/src
export FAST_ALIGN_BASE="../../tools/fast_align"

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en.txt lv base ../../data/wino_mt/base/lv.genders.txt \
    >../../evaluation_logs/baseline/gender_bias.txt

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en_anti.txt lv base ../../data/wino_mt/base/lv.genders.txt \
    >../../evaluation_logs/baseline/gender_bias_anti.txt

sh ../scripts/evaluate_language.sh ../../mt_gender/data/aggregates/en_pro.txt lv base ../../data/wino_mt/base/lv.genders.txt \
    >../../evaluation_logs/baseline/gender_bias_pro.txt

cd ../..
