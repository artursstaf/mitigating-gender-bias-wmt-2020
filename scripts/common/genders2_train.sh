#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
cd "$PROJECT_ROOT"

LANG=$1
EXPERIMENT=$2
VALIDATION=$3
DEVICE_IDS=$4

device_id_arr=($DEVICE_IDS)

python -m sockeye.train \
  -o models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
  -d data/"$LANG"/nmt_"$LANG"_"$EXPERIMENT"_prepare_data \
  --validation-source-factors data/"$LANG"/"$EXPERIMENT"/"$VALIDATION".genders.final.en \
  -vs data/"$LANG"/"$EXPERIMENT"/"$VALIDATION".final.en \
  -vt data/"$LANG"/"$EXPERIMENT"/"$VALIDATION".final."$LANG" \
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
  --weight-tying-type=src_trg_softmax \
  --num-embed 512:512 \
  --gradient-clipping-threshold=-1 \
  --initial-learning-rate=0.0001 \
  --max-num-checkpoint-not-improved 10 \
  --learning-rate-reduce-factor=0.7 \
  --weight-init xavier \
  --weight-init-scale 3.0 \
  --decode-and-evaluate -1 \
  --decode-and-evaluate-device-id "${device_id_arr[0]}" \
  --device-ids $DEVICE_IDS \
  --max-seq-len 128 \
  --checkpoint-interval 4000 \
  --weight-init-xavier-factor-type avg \
  --shared-vocab \
  --keep-last-params=35 \
  --source-factors-combine concat \
  --source-factors-num-embed 8 \
  --disable-device-locking
