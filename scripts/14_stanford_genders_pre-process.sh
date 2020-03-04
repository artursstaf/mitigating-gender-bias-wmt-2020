#!/bin/bash

cd ..

FOLDER=stanford_genders
TARGET_LANG=lv

mkdir data/$FOLDER

for file in corpus ; do

    lines_count=$(wc -l <data/$file.tc.$TARGET_LANG)

    cp data/$file.tc.$TARGET_LANG data/$FOLDER/$file.tc.$TARGET_LANG

    # Split file and process in parralel for efficiency reasons
    split data/stanford_genders/$file.tc.$TARGET_LANG data/stanford_genders/$file.tc.$TARGET_LANG -d -l$((lines_count / 5)) -a1
    for i in {0..5}; do
        touch data/stanford_genders/$file.tc.$TARGET_LANG$i
        python scripts/python/generate_genders.py --lang $TARGET_LANG --source data/stanford_genders/$file.tc.$TARGET_LANG$i \
            --output data/stanford_genders/$file.genders.$TARGET_LANG$i &
    done
    wait

    cd data/$FOLDER
    cat $file.genders."$TARGET_LANG"0 $file.genders."$TARGET_LANG"1 $file.genders."$TARGET_LANG"2 $file.genders."$TARGET_LANG"3 $file.genders.$"$TARGET_LANG"4 $file.genders."$TARGET_LANG"5 > $file.genders."$TARGET_LANG"
    for i in {0..5}; do
        rm $file.genders.$TARGET_LANG$i
        rm $file.tc.$TARGET_LANG$i
    done
    cd ../..

    # Get EN genders by aligning $TARGET_LANG genders to EN corpus
    python scripts/python/align_genders.py --target data/$file.tc.en \
        --source_genders data/$FOLDER/$file.genders.$TARGET_LANG \
        --source_target_alignment data/alignments/$file.$TARGET_LANG-en.align \
        >data/$FOLDER/$file.genders.en

    # Get randomized genders
    python scripts/python/randomly_include_genders.py \
    --genders data/$FOLDER/$file.genders.en \
    >data/$FOLDER/$file.threshold-genders.en

    # Get corresponding BPE format for genders
    python scripts/python/genders_bpe.py --genders data/$FOLDER/$file.threshold-genders.en \
    --bpe_sentences data/$file.tc.BPE.en \
    >data/$FOLDER/$file.threshold-genders.BPE.en

    # Format data for  experiment
    cat data/$FOLDER/$file.threshold-genders.BPE.en data/$file.u-genders.BPE.en >data/$FOLDER/$file.genders.BPE.en
    cat data/$file.tc.BPE.en data/$file.tc.BPE.en >data/$FOLDER/$file.tc.BPE.en
    cat data/$file.tc.BPE.$TARGET_LANG data/$file.tc.BPE.$TARGET_LANG >data/$FOLDER/$file.tc.BPE.$TARGET_LANG
done

# Sockeye prepare data
python -m sockeye.prepare_data -s data/$FOLDER/corpus.tc.BPE.en \
    -t data/$FOLDER/corpus.tc.BPE.$TARGET_LANG \
    -o data/nmt_"$FOLDER"_prepare_data \
    --source-factors data/$FOLDER/corpus.genders.BPE.en
