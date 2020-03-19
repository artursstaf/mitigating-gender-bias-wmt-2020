#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f ".")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
PYTHON_SCRIPTS=$PROJECT_ROOT/scripts/python
TOOLS=$PROJECT_ROOT/tools

LANG=lt

mkdir -p "$PROJECT_ROOT"/data/$LANG
cd "$PROJECT_ROOT"/data/$LANG

# Dowload parralel corpus
wget http://www.statmt.org/europarl/v9/training/europarl-v9.lt-en.tsv.gz &
wget https://s3.amazonaws.com/web-language-models/paracrawl/release3/en-lt.bicleaner07.tmx.gz &
wget http://data.statmt.org/wikititles/v1/wikititles-v1.lt-en.tsv.gz &
wget https://tilde-model.s3-eu-west-1.amazonaws.com/EESC2017.en-lt.tmx.zip &
wget https://tilde-model.s3-eu-west-1.amazonaws.com/rapid2016.en-lt.tmx.zip &
wget http://data.statmt.org/wmt19/translation-task/dev.tgz &
wait

# unzip
tar -zxvf dev.tgz dev/newsdev2019-enlt-src.en.sgm
tar -zxvf dev.tgz dev/newsdev2019-enlt-ref.lt.sgm
gunzip europarl-v9.lt-en.tsv.gz en-lt.bicleaner07.tmx.gz wikititles-v1.lt-en.tsv.gz

python "$PYTHON_SCRIPTS"/extract_zip.py *.zip

python2 "$TOOLS"/tmx2txt/TMX2Corpus.py .

python "$PYTHON_SCRIPTS"/tsv2txt.py wikititles-v1.lt-en.tsv lt en
python "$PYTHON_SCRIPTS"/tsv2txt.py europarl-v9.lt-en.tsv lt en

for lang in en lt; do
  cat europarl-v9.lt-en.$lang wikititles.$lang bitext.$lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang >corpus.tok.$lang
done

"$TOOLS"/moses-scripts/scripts/training/clean-corpus-n.perl corpus.tok en lt corpus.clean 1 80 corpus.retained

for lang in en lt; do
  "$TOOLS"/moses-scripts/scripts/recaser/train-truecaser.perl -model ../../models/truecase-model.$lang -corpus corpus.tok.$lang
  "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl <corpus.clean.$lang >corpus.tc.$lang -model ../../models/truecase-model.$lang
done

for lang in en lt; do
  side="src"
  if [ $lang = lt ]; then
    side="ref"
  fi
  "$TOOLS"/moses-scripts/scripts/generic/input-from-sgm.perl <dev/newsdev2019-enlt-$side.$lang.sgm |
    "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l $lang |
    "$TOOLS"/moses-scripts/scripts/tokenizer/tokenizer.perl -a -l $lang |
    "$TOOLS"/moses-scripts/scripts/recaser/truecase.perl -model ../../models/truecase-model.$lang \
      >newsdev2019.tc.$lang

done

rm bitext.* *.tgz EESC* *bicleaner* europarl* rapid2016* wikititles* **/*.sgm *.tok.* *.clean.*
rmdir dev
