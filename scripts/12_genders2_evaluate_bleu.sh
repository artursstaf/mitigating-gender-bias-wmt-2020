#!/bin/bash

cd ..
mkdir -p data/dev_translations/genders2
mkdir -p evaluation_logs/genders2

# True genders
python -m sockeye.translate -m models/nmt_genders2  --input-factors data/newsdev2017.genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders2/true_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders2/true_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders2/true_genders_bleu.txt

# Unkown genders
python -m sockeye.translate -m models/nmt_genders2  --input-factors data/genders1/newsdev2017.u-genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders2/unknown_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders2/unknown_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders2/unkown_genders_bleu.txt

# Random genders
python -m sockeye.translate -m models/nmt_genders2  --input-factors data/genders1/newsdev2017.r-genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
    sed -r 's/@@( |$)//g' >data/dev_translations/genders2/random_newsdev2017.tc.lv

python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/genders2/random_newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/genders2/random_genders_bleu.txt
