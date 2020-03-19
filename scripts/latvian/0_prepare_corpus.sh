#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f ".")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")

# Dowload parralel corpus
wget http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/corpus.tc.en.gz
gunzip corpus.tc.en.gz
wget http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/corpus.tc.lv.gz
gunzip corpus.tc.lv.gz
curl http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/dev.tgz | tar xvzf -
rm *.sgm

(
  cd ../models
  curl http://data.statmt.org/wmt17/translation-task/preprocessed/lv-en/true.tgz | tar xvzf -
)
