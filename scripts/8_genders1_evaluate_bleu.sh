#!/bin/bash

cd ..
mkdir -p data/dev_translations/genders1
mkdir -p evaluation_logs/genders1

# True genders
python -m sockeye.translate -m models/nmt_genders1  --input-factors data/newsdev2017.genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders1/true_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders1/true_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders1/true_genders_bleu.txt

# Unkown genders
python -m sockeye.translate -m models/nmt_genders1  --input-factors data/genders1/newsdev2017.u-genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders1/unknown_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders1/unknown_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders1/unkown_genders_bleu.txt

# Random genders
python scripts/python/random_genders.py --genders data/newsdev2017.genders.en >g.tmp
python scripts/python/genders_bpe.py --genders g.tmp --bpe_sentences data/newsdev2017.tc.BPE.en >data/genders1/newsdev2017.r-genders.BPE.en
rm g.tmp

python -m sockeye.translate -m models/nmt_genders1  --input-factors data/genders1/newsdev2017.r-genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders1/random_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders1/random_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders1/random_genders_bleu.txt
