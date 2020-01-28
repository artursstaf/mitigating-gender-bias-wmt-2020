#!/bin/bash

cd ..

# Translate dev
mkdir -p data/dev_translations/baseline
mkdir -p evaluation_logs/baseline

python -m sockeye.translate -m models/nmt_base <data/newsdev2017.tc.BPE.en |
    sed -r 's/@@( |$)//g' >data/dev_translations/baseline/newsdev2017.tc.lv

# Run bleu against reference translaiton
python -m sockeye.evaluate \
    --references data/newsdev2017.tc.lv \
    --hypotheses data/dev_translations/baseline/newsdev2017.tc.lv \
    --metrics bleu \
    >evaluation_logs/baseline/bleu.txt
