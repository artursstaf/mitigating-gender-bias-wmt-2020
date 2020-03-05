#!/bin/bash
cd ../../data

LANG=ru
mkdir $LANG
cd $LANG

# Dowload parralel corpus
wget http://data.statmt.org/wmt17/translation-task/preprocessed/$LANG-en/corpus.tc.en.gz
gunzip corpus.tc.en.gz
wget http://data.statmt.org/wmt17/translation-task/preprocessed/$LANG-en/corpus.tc.$LANG.gz
gunzip corpus.tc.$LANG.gz
curl http://data.statmt.org/wmt17/translation-task/preprocessed/$LANG-en/dev.tgz | tar xvzf -
rm *.sgm

(
  cd ../../models
  curl http://data.statmt.org/wmt17/translation-task/preprocessed/$LANG-en/true.tgz | tar xvzf -
)

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
