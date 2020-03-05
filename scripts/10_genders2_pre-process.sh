#!/bin/bash

cd ..

mkdir data/genders2

for file in newsdev2017 corpus; do
  # Get randomized genders
  python scripts/python/randomly_include_genders.py \
    --genders data/$file.genders.en \
    >data/genders2/$file.threshold-genders.en

  # Get corresponding BPE format for genders
  python scripts/python/genders_bpe.py --genders data/genders2/$file.threshold-genders.en \
    --bpe_sentences data/$file.tc.BPE.en \
    >data/genders2/$file.threshold-genders.BPE.en

  # Format data for second experiment
  sed 's/[MFN]/U/g' <data/$file.genders.BPE.en >data/$file.u-genders.BPE.en
  cat data/genders2/$file.threshold-genders.BPE.en data/$file.u-genders.BPE.en >data/genders2/$file.genders.BPE.en
  cat data/$file.tc.BPE.en data/$file.tc.BPE.en >data/genders2/$file.tc.BPE.en
  cat data/$file.tc.BPE.lv data/$file.tc.BPE.lv >data/genders2/$file.tc.BPE.lv
done

# Sockeye prepare data
python -m sockeye.prepare_data -s data/genders2/corpus.tc.BPE.en \
  -t data/genders2/corpus.tc.BPE.lv \
  -o data/nmt_genders2_prepare_data \
  --source-factors data/genders2/corpus.genders.BPE.en \
  --num-words 50000 \
  --max-seq-len 128 \
  --shared-vocab
