#!/bin/bash

cd ..

FOLDER=stanford_genders
TARGET_LANG=lv
CHUNK_SIZE=1 # Max 9
CUDA_DEVICES=(0)

mkdir data/$FOLDER

for file in newsdev2017; do

  cp data/$file.tc.$TARGET_LANG data/$FOLDER/$file.tc.$TARGET_LANG

  # Split file and process in parallel for efficiency reasons
  split data/$FOLDER/$file.tc.$TARGET_LANG data/$FOLDER/$file.tc.$TARGET_LANG --numeric-suffixes=1 -n l/$CHUNK_SIZE
  for i in $(seq 1 $CHUNK_SIZE); do
    arr_len=${#CUDA_DEVICES[@]}
    export CUDA_VISIBLE_DEVICES=${CUDA_DEVICES[(i - 1) % arr_len]}

    python scripts/python/generate_genders.py --lang $TARGET_LANG --source data/$FOLDER/$file.tc."$TARGET_LANG"0"$i" \
      --output data/$FOLDER/$file.genders."$TARGET_LANG"0"$i" &
  done
  wait

  (
    cd data/$FOLDER || exit
    cat "$file.genders.$TARGET_LANG"?* >$file.genders."$TARGET_LANG"
    rm "$file.genders.$TARGET_LANG"?*
    rm "$file.tc.$TARGET_LANG"?*
  )

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
  sed 's/[MFN]/U/g' <data/$FOLDER/$file.threshold-genders.BPE.en >data/$file.u-genders.BPE.en
  cat data/$FOLDER/$file.threshold-genders.BPE.en data/$file.u-genders.BPE.en >data/$FOLDER/$file.genders.BPE.en
  cat data/$file.tc.BPE.en data/$file.tc.BPE.en >data/$FOLDER/$file.tc.BPE.en
  cat data/$file.tc.BPE.$TARGET_LANG data/$file.tc.BPE.$TARGET_LANG >data/$FOLDER/$file.tc.BPE.$TARGET_LANG
done

# Sockeye prepare data
python -m sockeye.prepare_data -s data/$FOLDER/corpus.tc.BPE.en \
  -t data/$FOLDER/corpus.tc.BPE.$TARGET_LANG \
  -o data/nmt_"$FOLDER"_prepare_data \
  --source-factors data/$FOLDER/corpus.genders.BPE.en \
  --num-words 50000 \
  --max-seq-len 128 \
  --shared-vocab
