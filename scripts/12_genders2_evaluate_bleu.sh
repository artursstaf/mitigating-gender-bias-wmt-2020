#!/bin/bash

cd ..
mkdir -p data/dev_translations/genders2
mkdir -p evaluation_logs/genders2

for type in "true " "unkown u-" "random r-"; do
    set -- $type

    python -m sockeye.translate -m models/nmt_genders2 --input-factors data/newsdev2017.$2genders.BPE.en --input data/newsdev2017.tc.BPE.en |
        sed -r 's/@@( |$)//g' >data/dev_translations/genders2/$1_newsdev2017.tc.lv

    python -m sockeye.evaluate \
        --references data/newsdev2017.tc.lv \
        --hypotheses data/dev_translations/genders2/$1_newsdev2017.tc.lv \
        --metrics bleu \
        >evaluation_logs/genders2/bleu_$1.txt

done
