#!/bin/bash

cd ..

# Translate dev
mkdir -p data/dev_translations/baseline
mkdir -p evaluation_logs/baseline

python -m sockeye.translate -m models/nmt_base <data/newsdev2017.tc.BPE.en |
    sed -r 's/@@( |$)//g' >data/dev_translations/baseline/newsdev2017.tc.lv

export EXP_MOSES_SCRIPTS_DIR=/home/marcis/hpcd/moses-bin-131030/moses-scripts


ref=data/dev_translations/baseline/newsdev2017.tc.lv
cat $ref \
    | sed 's/\@\@ //g' \
    | $EXP_MOSES_SCRIPTS_DIR/generic/multi-bleu.perl $ref \
	| sed -r 's/BLEU = ([0-9.]+),.*/\1/' >evaluation_logs/baseline/bleu.txt
