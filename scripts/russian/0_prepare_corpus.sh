#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f ".")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
PYTHON_SCRIPTS=$PROJECT_ROOT/scripts/python
TOOLS=$PROJECT_ROOT/tools

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
