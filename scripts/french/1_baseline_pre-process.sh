#!/bin/bash
cd ../../data

LANG=fr
mkdir $LANG
cd $LANG

files=(
  http://www.statmt.org/wmt13/training-parallel-europarl-v7.tgz
  http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz
  http://www.statmt.org/wmt13/training-parallel-un.tgz
  http://www.statmt.org/wmt15/training-parallel-nc-v10.tgz
  http://www.statmt.org/wmt10/training-giga-fren.tar
)

for file in "${files[@]}"; do
  wget "$file"
done

# cat all


operations=30000
threshold=50

# Build BPE vocabulary
subword-nmt learn-joint-bpe-and-vocab --input corpus.tc.en corpus.tc.$LANG -s $operations -o bpe.codes --write-vocabulary bpe.vocab.en bpe.vocab.$LANG

for file in newstest2014 corpus; do
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold <$file.tc.en >$file.tc.BPE.en
  subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.$LANG --vocabulary-threshold $threshold <$file.tc.$LANG >$file.tc.BPE.$LANG
done

# Prepare data for sockeye training
python -m sockeye.prepare_data -s corpus.tc.BPE.en -t corpus.tc.BPE.$LANG -o nmt_"$LANG"_base_prepare_data \
  --num-words 50000 \
  --max-seq-len 128 \
  --shared-vocab
