#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
PYTHON_SCRIPTS=$PROJECT_ROOT/scripts/python
TOOLS=$PROJECT_ROOT/tools

echo "$PYTHON_SCRIPTS"

LANG=de

mkdir -p "$PROJECT_ROOT"/data/$LANG
cd "$PROJECT_ROOT"/data/$LANG

# Dowload parralel corpus
wget http://www.statmt.org/europarl/v9/training/europarl-v9.de-en.tsv.gz &
wget http://data.statmt.org/news-commentary/v14/training/news-commentary-v14.de-en.tsv.gz &
wget http://data.statmt.org/wikititles/v1/wikititles-v1.de-en.tsv.gz &
wget https://s3.amazonaws.com/web-language-models/paracrawl/release6/en-de.txt.gz &
wget http://www.statmt.org/wmt13/training-parallel-commoncrawl.tgz &
wait

# unzip
gunzip europarl-v9.de-en.tsv.gz news-commentary-v14.de-en.tsv.gz wikititles-v1.de-en.tsv.gz en-de.txt.gz

tar -xvzf training-parallel-commoncrawl.tgz

python "$PYTHON_SCRIPTS"/tsv2txt.py wikititles-v1.de-en.tsv de en
python "$PYTHON_SCRIPTS"/tsv2txt.py europarl-v9.de-en.tsv de en
python "$PYTHON_SCRIPTS"/tsv2txt.py news-commentary-v14.de-en.tsv de en

python2 "$TOOLS"/tmx2txt/TMX2Corpus.py .

for lang in en de; do
  echo Normalize and clean $lang
  cat europarl-v9.de-en.$lang news-commentary-v14.de-en.$lang wikititles-v1.de-en.$lang en-de.$lang  commoncrawl.de-en.$lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang >corpus.tok.$lang
done

echo clean
"$TOOLS"/moses-scripts/scripts/training/clean-corpus-n.perl corpus.tok en de corpus.clean 1 80 corpus.retained

for lang in en de; do
  truecase $lang
  "$TOOLS"/moses-scripts/scripts/recaser/train-truecaser.perl -model ../../models/truecase-model.$lang -corpus corpus.tok.$lang
  "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl <corpus.clean.$lang >corpus.tc.$lang -model ../../models/truecase-model.$lang
done

for lang in en de; do
  side="src"
  if [ $lang = de ]; then
    side="ref"
  fi
  "$TOOLS"/moses-scripts/scripts/generic/input-from-sgm.perl <newstest2017-ende-$side.$lang.sgm |
    "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang |
    "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model ../../models/truecase-model.$lang \
      >newstest2017.tc.$lang

done

for lang in en de; do
  side="src"
  if [ $lang = de ]; then
    side="ref"
  fi
  "$TOOLS"/moses-scripts/scripts/generic/input-from-sgm.perl <newstest2018-ende-$side.$lang.sgm |
    "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang |
    "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model ../../models/truecase-model.$lang \
      >newstest2018.tc.$lang
done

rm bitext.* *.tgz EESC* *bicleaner* europarl* rapid2016* wikititles* **/*.sgm *.tok.* *.clean.*
rmdir dev