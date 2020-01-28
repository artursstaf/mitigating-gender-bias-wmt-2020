#!/bin/bash
cd ../data

# Dowload parralel corpus
wget http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/corpus.tc.en.gz
gunzip corpus.tc.en.gz
wget http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/corpus.tc.lv.gz
gunzip corpus.tc.lv.gz
curl http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/dev.tgz | tar xvzf -
rm *.sgm

operations=30000
threshold=50

# Build BPE vocabulary
subword-nmt learn-joint-bpe-and-vocab --input corpus.tc.en corpus.tc.lv -s $operations -o bpe.codes --write-vocabulary bpe.vocab.en bpe.vocab.lv

# Apply BPE corpus
subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold < corpus.tc.en > corpus.tc.BPE.en
subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.lv --vocabulary-threshold $threshold < corpus.tc.lv > corpus.tc.BPE.lv

# Apply BPE dev
subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold < newsdev2017.tc.en > newsdev2017.tc.BPE.en
subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.lv --vocabulary-threshold $threshold < newsdev2017.tc.lv > newsdev2017.tc.BPE.lv

# Prepare data for sockeye training
python -m sockeye.prepare_data -s corpus.tc.BPE.en -t corpus.tc.BPE.lv -o nmt_base_prepare_data
