#!/bin/bash

cd ..

# Get randomized genders
mkdir data/genders2
python scripts/python/randomly_include_genders.py \
    --genders data/corpus.genders.en \
    >data/genders2/corpus.threshold-genders.en

python scripts/python/randomly_include_genders.py \
    --genders data/newsdev2017.genders.en \
    >data/genders2/newsdev2017.threshold-genders.en

# Get corresponding BPE format for genders
python scripts/python/genders_bpe.py --genders data/genders2/newsdev2017.threshold-genders.en \
    --bpe_sentences data/newsdev2017.tc.BPE.en \
    >data/genders2/newsdev2017.threshold-genders.BPE.en

python scripts/python/genders_bpe.py --genders data/genders2/corpus.threshold-genders.en \
    --bpe_sentences data/corpus.tc.BPE.en \
    >data/genders2/corpus.threshold-genders.BPE.en

# Format data for second experiment
cat data/genders2/corpus.threshold-genders.BPE.en data/genders1/corpus.u-genders.BPE.en >data/genders2/corpus.genders.BPE.en
cat data/genders2/newsdev2017.threshold-genders.BPE.en data/genders1/newsdev2017.u-genders.BPE.en >data/genders2/newsdev2017.genders.BPE.en

cat data/corpus.tc.BPE.en data/corpus.tc.BPE.en >data/genders2/corpus.tc.BPE.en
cat data/corpus.tc.BPE.lv data/corpus.tc.BPE.lv >data/genders2/corpus.tc.BPE.lv

cat data/newsdev2017.tc.BPE.en data/newsdev2017.tc.BPE.en >data/genders2/newsdev2017.tc.BPE.en
cat data/newsdev2017.tc.BPE.lv data/newsdev2017.tc.BPE.lv >data/genders2/newsdev2017.tc.BPE.lv

# Sockeye prepare data
python -m sockeye.prepare_data -s data/genders2/corpus.tc.BPE.en \
    -t data/genders2/corpus.tc.BPE.lv \
    -o data/nmt_genders2_prepare_data \
    --source-factors data/genders2/corpus.genders.BPE.en
