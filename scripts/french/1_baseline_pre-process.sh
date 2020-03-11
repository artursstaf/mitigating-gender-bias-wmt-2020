#!/bin/bash
cd ../..

LANG=fr
NUM_WORD=50000
MAX_SEQ=128
BPE_OPS=30000
BPE_THRESHOLD=50
VALIDATION=develop
CORPUS=corpus

mkdir -p $LANG

(
  cd data/$LANG
  # Build BPE vocabulary
  subword-nmt learn-joint-bpe-and-vocab --input $CORPUS.tc.en $CORPUS.tc.$LANG -s $BPE_OPS -o bpe.codes --write-vocabulary bpe.vocab.en bpe.vocab.$LANG

  for file in $VALIDATION $CORPUS; do
    subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $BPE_THRESHOLD <$file.tc.en >$file.tc.BPE.en
    subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.$LANG --vocabulary-threshold $BPE_THRESHOLD <$file.tc.$LANG >$file.tc.BPE.$LANG
  done

  # Prepare data for sockeye training
  python -m sockeye.prepare_data -s $CORPUS.tc.BPE.en -t $CORPUS.tc.BPE.$LANG -o nmt_"$LANG"_base_prepare_data \
    --num-words $NUM_WORD \
    --max-seq-len $MAX_SEQ \
    --shared-vocab
)
