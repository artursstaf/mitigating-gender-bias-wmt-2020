#!/bin/bash

cd ../..

VALIDATION=newstest2014
LANG=ru
EXPERIMENT=base

# Translate dev
mkdir -p data/dev_translations/$LANG/$EXPERIMENT
mkdir -p evaluation_logs/$LANG/$EXPERIMENT

python -m sockeye.translate -m models/$LANG/nmt_"$LANG"_"$EXPERIMENT" <data/$LANG/$VALIDATION.tc.BPE.en |
  sed -r 's/@@( |$)//g' >data/dev_translations/$LANG/$EXPERIMENT/$VALIDATION.tc.$LANG

# Run bleu against reference translaiton
python -m sockeye.evaluate \
--references data/$LANG/$VALIDATION.tc.$LANG \
--hypotheses data/dev_translations/$LANG/$EXPERIMENT/$VALIDATION.tc.$LANG \
--metrics bleu \
>evaluation_logs/$LANG/$EXPERIMENT/bleu.txt
