#!/bin/bash

cd ..
mkdir -p data/dev_translations/genders1
mkdir -p evaluation_logs/genders1

# Generate random genders
python scripts/python/random_genders.py --genders data/newsdev2017.genders.en >g.tmp
python scripts/python/genders_bpe.py --genders g.tmp --bpe_sentences data/newsdev2017.tc.BPE.en >data/newsdev2017.r-genders.BPE.en
rm g.tmp

for type in "true " "unkown u-" "random r-"; do
    set -- $type

    python -m sockeye.translate -m models/nmt_genders1  --input-factors data/newsdev2017.$2genders.BPE.en --input data/newsdev2017.tc.BPE.en  |
        sed -r 's/@@( |$)//g' >data/dev_translations/genders1/$1_newsdev2017.tc.lv

    python -m sockeye.evaluate \
        --references data/newsdev2017.tc.lv \
        --hypotheses data/dev_translations/genders1/$1_newsdev2017.tc.lv \
        --metrics bleu \
        >evaluation_logs/genders1/bleu_$1.txt
done
