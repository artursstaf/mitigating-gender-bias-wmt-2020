# Mitigating Gender Bias in Machine Translation: Target Language Grammatical Gender Projections Onto Source Language
Repository contains code and partial data for experiments described in [Mitigating Gender Bias in Machine Translation: Target Language Grammatical Gender Projections Onto Source Language](https://arxiv.org/abs/2010.06203)


### Requirements
Conda is recommended way to run experiments `conda create -n gender-bias python=3.7`. <br>
Also make sure you have system-wide dependencies `sudo apt install build-essential swig python-dev libgoogle-perftools-dev libsparsehash-dev`.<br>
Then switch into conda environment and install necessary tools via `scripts/install_tools.sh`.

### Running experiments
Experiments are organized per language pair (training corpora).<br>
Running bash scripts in order from `scripts/{language}/*.sh` will prepare data, train model and evaluate BLEU and WinoMT scores.
Experiments for `latvian_imba` (large proprietary Tilde corpora) are not reproducible.<br>
Each language pair trains 2 NMT systems baseline(base) with no TGA and gendered(genders2) with TGA in training data. 

### Evaluation results
Evaluation metrics are aggregated in 
`evaluation_logs/{languate}/{experiment}/`.<br>
WinoMT test set translations are stored in 
`data/wino_mt/{langage}/{experiment}`.<br>
Newstest translations can be found in `data/dev_translations/{language}/{experiment}`.

### Scripts
Paper-specific data preparation scripts can be found in `scripts/python`. Example usage can be found in `scripts/common/` where these scripts are invoked.
- `generate_genders.py` extracts gender annotations (M/F/N/U) using `Stanza` tagger
- `align_genders.py`  projects target gender annotations onto source side tokens
- `genders_bpe.py` copy word level gender annotations to their respective sub-word parts
- `randomly_include_genders.py` applies dropout to TGA
- `wino_mt_genders.py` extract gold gender annotations from WinoMT dataset
- `wino_mt_genders_allen.py` generate gender annotations using AllenNLP coreference resolution tool
