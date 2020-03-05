#!/bin/bash

FOLDER=genders2

cd ..

python -m sockeye.train --o \
  models/nmt_$FOLDER \
  d data/nmt_"$FOLDER"_prepare_data \
  -vs data/$FOLDER/newsdev2017.tc.BPE.en \
  -vt data/$FOLDER/newsdev2017.tc.BPE.lv \
  --validation-source-factors data/$FOLDER/newsdev2017.genders.BPE.en \
  --encoder=transformer \
  --decoder=transformer \
  --num-layers=6:6 \
  --transformer-model-size=512 \
  --transformer-attention-heads=8 \
  --transformer-feed-forward-num-hidden=1024 \
  --transformer-positional-embedding-type=fixed \
  --transformer-preprocess=n \
  --transformer-postprocess=dr \
  --transformer-dropout-attention=0.1 \
  --transformer-dropout-act=0.1 \
  --transformer-dropout-prepost=0.1 \
  --max-seq-len 60 \
  --weight-tying-type=src_trg_softmax \
  --weight-init=xavier \
  --weight-init-scale=3.0 \
  --weight-init-xavier-factor-type=avg \
  --num-embed=512:512 \
  --optimizer=adam \
  --optimized-metric=perplexity \
  --label-smoothing=0.1 \
  --gradient-clipping-threshold=-1 \
  --initial-learning-rate=0.0002 \
  --learning-rate-reduce-num-not-improved=8 \
  --learning-rate-reduce-factor=0.9 \
  --learning-rate-scheduler-type=plateau-reduce \
  --learning-rate-decay-optimizer-states-reset=best \
  --learning-rate-decay-param-reset \
  --max-num-checkpoint-not-improved=32 \
  --batch-type=word \
  --batch-size=2048 \
  --checkpoint-interval=2000 \
  --decode-and-evaluate=150 \
  --keep-last-params=35 \
  --decode-and-evaluate-use-cpu \
  --source-factors-combine concat \
  --source-factors-num-embed 8
