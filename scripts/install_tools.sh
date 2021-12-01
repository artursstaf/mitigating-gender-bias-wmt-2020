#!/bin/bash

set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT="$(dirname "$DIR")"
cd "$PROJECT_ROOT"

mkdir -p models
mkdir -p data
mkdir -p tools

CUDA_VERSION=101

# Install gpu support and tensorboard
conda install -c anaconda tensorflow-gpu
pip install mxboard tensorboard

# Install sockeye with CUDA 10.0
wget https://raw.githubusercontent.com/awslabs/sockeye/master/requirements/requirements.gpu-cu${CUDA_VERSION}.txt
pip install sockeye --no-deps -r requirements.gpu-cu${CUDA_VERSION}.txt
rm requirements.gpu-cu${CUDA_VERSION}.txt

# Install AllenNLP
pip install allennlp==1.0.0 allennlp-models==1.0.0 scikit-learn

# Install pre-processing tools
pip install subword-nmt
git clone git@github.com:marian-nmt/moses-scripts.git ./tools/moses-scripts
git clone git@gist.github.com:9128457.git ./tools/tmx2txt

# Install fast-align
git clone git@github.com:clab/fast_align.git ./tools/fast_align
mkdir ./tools/fast_align/build
cd ./tools/fast_align/build
cmake ..
make
cd ../../..

# Download forked mt_gender (gender bias evaluation) repository
git clone git@github.com:artursstaf/mt_gender.git
(
  cd mt_gender
  git pull
  git checkout genders-file
)
# Additional packages
pip install docopt tqdm spacy pymorphy2 argparse stanza sacrebleu
pip install neuralcoref
python -m spacy download en
