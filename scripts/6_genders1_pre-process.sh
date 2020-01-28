#!/bin/bash

cd ..

mkdir data/alignments
mkdir data/genders1

for file in newsdev2017 corpus; do

    # Generate word alignments
    paste -d "|" data/$file.tc.lv data/$file.tc.en | sed 's/|/ ||| /g' >data/alignments/$file.lv-en.txt
    cd tools/fast_align/build
    ./fast_align -i ../../../data/alignments/$file.lv-en.txt -d -o -v >../../../data/alignments/$file.lv-en.align
    cd ../../../

    # Get LV genders by morph analysis
    cd tools/morph-analysis
    # This is a time consuming step. Main corpus takes aprox 30 hours
    ./gradlew run --args="../../data/$file.tc.lv ../../data/$file.genders.lv"
    cd ../../

    # Get EN genders by aligning LV genders to EN corpus
    python scripts/python/align_genders.py --target data/$file.tc.en \
    --source_genders data/$file.genders.lv \
    --source_target_alignment data/alignments/$file.lv-en.align \
    >data/$file.genders.en

    # Get corresponding BPE format for genders
    python scripts/python/genders_bpe.py --genders data/$file.genders.en \
    --bpe_sentences data/$file.tc.BPE.en \
    >data/$file.genders.BPE.en

    # Format data for first experiment
    sed 's/[MFN]/U/g' <data/$file.genders.BPE.en >data/$file.u-genders.BPE.en
    cat data/$file.genders.BPE.en data/$file.u-genders.BPE.en >data/genders1/$file.genders.BPE.en

    cat data/$file.tc.BPE.en data/$file.tc.BPE.en >data/genders1/$file.tc.BPE.en
    cat data/$file.tc.BPE.lv data/$file.tc.BPE.lv >data/genders1/$file.tc.BPE.lv

done

# Sockeye prepare data
python -m sockeye.prepare_data -s data/genders1/corpus.tc.BPE.en \
                        -t data/genders1/corpus.tc.BPE.lv \
                        -o data/nmt_genders1_prepare_data \
                        --source-factors data/genders1/corpus.genders.BPE.en
