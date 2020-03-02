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

for file in newsdev2017 corpus; do
    subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.en --vocabulary-threshold $threshold < $file.tc.en > $file.tc.BPE.en
    subword-nmt apply-bpe -c bpe.codes --vocabulary bpe.vocab.lv --vocabulary-threshold $threshold < $file.tc.lv > $file.tc.BPE.lv
done

# Prepare data for sockeye training
python -m sockeye.prepare_data -s corpus.tc.BPE.en -t corpus.tc.BPE.lv -o nmt_base_prepare_data \
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
--device-ids -2 \
--max-seq-len 128 \
--checkpoint-frequency 10000 \
--weight-init-xavier-factor-type avg
