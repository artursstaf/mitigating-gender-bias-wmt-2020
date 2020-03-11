#!/bin/bash

cd ../../

VALIDATION=newstest2014
LANG=ru
EXPERIMENT=genders2

mkdir -p data/dev_translations/$LANG/$EXPERIMENT
mkdir -p evaluation_logs/$LANG/$EXPERIMENT

# Generate random genders
python scripts/python/random_genders.py --genders data/$LANG/$EXPERIMENT/$VALIDATION.genders.en >g.tmp
python scripts/python/genders_bpe.py --genders g.tmp --bpe_sentences data/$LANG/$VALIDATION.tc.BPE.en >data/$LANG/$VALIDATION.r-genders.BPE.en
rm g.tmp

for type in "true " "unkown u-" "random r-"; do
  set -- $type

  python -m sockeye.translate -m models/$LANG/nmt_"$LANG"_$EXPERIMENT --input-factors data/$LANG/$EXPERIMENT/$VALIDATION."$2"genders.BPE.en --input data/$LANG/$EXPERIMENT/$VALIDATION.tc.BPE.en |
    sed -r 's/@@( |$)//g' >data/dev_translations/$LANG/$EXPERIMENT/"$1"_$VALIDATION.tc.$LANG

  python -m sockeye.evaluate \
    --references data/$LANG/$EXPERIMENT/$VALIDATION.tc.$LANG \
    --hypotheses data/dev_translations/$LANG/$EXPERIMENT/"$1"_$VALIDATION.tc.$LANG \
    --metrics bleu \
    >evaluation_logs/$LANG/$EXPERIMENT/bleu_"$1".txt
done
