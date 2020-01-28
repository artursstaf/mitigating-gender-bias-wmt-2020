#!/bin/bash

cd ..

# Generate word alignments
mkdir data/alignments
paste -d "|" data/corpus.tc.lv data/corpus.tc.en | sed 's/|/ ||| /g' >data/alignments/corpus.lv-en.txt
paste -d "|" data/newsdev2017.tc.lv data/newsdev2017.tc.en | sed 's/|/ ||| /g' >data/alignments/dev.lv-en.txt

cd tools/fast_align/build
./fast_align -i ../../../data/alignments/corpus.lv-en.txt -d -o -v >../../../data/alignments/corpus.lv-en.align
./fast_align -i ../../../data/alignments/dev.lv-en.txt -d -o -v >../../../data/alignments/dev.lv-en.align
cd ../../../

# Get LV genders by morph analysis
cd tools/morph-analysis
./gradlew run --args='../../data/newsdev2017.tc.lv ../../data/newsdev2017.genders.lv'

# This is a time consuming step - takes aprox 30 hours
./gradlew run --args='../../data/corpus.tc.lv ../../data/corpus.genders.lv'
cd ../../

# Get EN genders by aligning LV genders to EN corpus
python scripts/python/align_genders.py --target data/newsdev2017.tc.en \
    --source_genders data/newsdev2017.genders.lv \
    --source_target_alignment data/alignments/dev.lv-en.align \
    >data/newsdev2017.genders.en

python scripts/python/align_genders.py --target data/corpus.tc.en \
    --source_genders data/corpus.genders.lv \
    --source_target_alignment data/alignments/corpus.lv-en.align \
    >data/corpus.genders.en

# Get corresponding BPE format for genders
python scripts/python/genders_bpe.py --genders data/newsdev2017.genders.en \
    --bpe_sentences data/newsdev2017.tc.BPE.en \
    >data/newsdev2017.genders.BPE.en

python scripts/python/genders_bpe.py --genders data/corpus.genders.en \
    --bpe_sentences data/corpus.tc.BPE.en \
    >data/corpus.genders.BPE.en

# Format data for first experiment
mkdir data/genders1
sed 's/[MFN]/U/g' <data/corpus.genders.BPE.en >data/genders1/corpus.u-genders.BPE.en
sed 's/[MFN]/U/g' <data/newsdev2017.genders.BPE.en >data/genders1/newsdev2017.u-genders.BPE.en

cat data/corpus.genders.BPE.en data/genders1/corpus.u-genders.BPE.en >data/genders1/corpus.genders.BPE.en
cat data/newsdev2017.genders.BPE.en data/genders1/newsdev2017.u-genders.BPE.en >data/genders1/newsdev2017.genders.BPE.en

cat data/corpus.tc.BPE.en data/corpus.tc.BPE.en >data/genders1/corpus.tc.BPE.en
cat data/corpus.tc.BPE.lv data/corpus.tc.BPE.lv >data/genders1/corpus.tc.BPE.lv

cat data/newsdev2017.tc.BPE.en data/newsdev2017.tc.BPE.en >data/genders1/newsdev2017.tc.BPE.en
cat data/newsdev2017.tc.BPE.lv data/newsdev2017.tc.BPE.lv >data/genders1/newsdev2017.tc.BPE.lv

# Sockeye prepare data
python -m sockeye.prepare_data -s data/genders1/corpus.tc.BPE.en \
                        -t data/genders1/corpus.tc.BPE.lv \
                        -o data/nmt_genders1_prepare_data \
                        --source-factors data/genders1/corpus.genders.BPE.en
