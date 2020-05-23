#!/bin/bash
  set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
cd "$PROJECT_ROOT"/data

LANG=$1
VALIDATION=$2
CORPUS=$3
EXPERIMENT=base

mkdir -p "$LANG"
cd "$LANG"

operations=30000
threshold=50

# Build BPE vocabulary
subword-nmt learn-joint-bpe-and-vocab --input "$CORPUS".tc.en "$CORPUS".tc."$LANG" -s $operations -o bpe.codes --write-vocabulary bpe.vocab.en bpe.vocab."$LANG"

for file in "$VALIDATION" "$CORPUS"; do
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold <"$file".tc.en >"$file".tc.BPE.en
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab."$LANG" --vocabulary-threshold $threshold <"$file".tc."$LANG" >"$file".tc.BPE."$LANG"
done

# Prepare data for sockeye training
python -m sockeye.prepare_data \
  -s "$CORPUS".tc.BPE.en \
  -t "$CORPUS".tc.BPE."$LANG" \
  -o nmt_"$LANG"_"$EXPERIMENT"_prepare_data \
  --num-words 50000 \
  --max-seq-len 128 \
  --shared-vocab
