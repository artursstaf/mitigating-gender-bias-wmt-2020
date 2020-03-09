#!/bin/bash

LANG=ru
EXPERIMENT=base
DEVICEIDS=3,4
VALIDATION=newstest2014

cd ../../

python -m sockeye.train \
-o models/$LANG/nmt_"$LANG"_"$EXPERIMENT" \
-d data/$LANG/nmt_"$LANG"_"$EXPERIMENT"_prepare_data \
-vs data/$LANG/$VALIDATION.tc.BPE.en \
-vt data/$LANG/$VALIDATION.tc.BPE.$LANG \
--batch-type=word \
--batch-size=4096 \
--embed-dropout=0:0 \
--encoder=transformer \
--decoder=transformer \
--num-layers=6:6 \
--transformer-model-size=512 \
--transformer-attention-heads=8 \
--transformer-feed-forward-num-hidden=2048 \
--transformer-preprocess=n \
--transformer-postprocess=dr \
--transformer-dropout-attention=0.1 \
--transformer-dropout-act=0.1 \
--transformer-dropout-prepost=0.1 \
--transformer-positional-embedding-type fixed \
--num-words 50000 \
--label-smoothing 0.1 \
--weight-tying \
--weight-tying-type=src_trg_softmax \
--num-embed 512:512 \
--gradient-clipping-threshold=-1 \
--initial-learning-rate=0.0001 \
--max-num-checkpoint-not-improved 10 \
--learning-rate-reduce-factor=0.7 \
--weight-init xavier \
--weight-init-scale 3.0 \
--decode-and-evaluate -1 \
--device-ids $DEVICEIDS \
--max-seq-len 128 \
--checkpoint-frequency 4000 \
--weight-init-xavier-factor-type avg \
--shared-vocab \
--keep-last-params=35
