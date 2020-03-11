from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent.parent

# Moses tools
MOSES_SCRIPTS = PROJECT_ROOT / 'tools' / 'moses-scripts' / 'scripts'
NORMALIZE_PUNCTUATION = MOSES_SCRIPTS / 'tokenizer' / 'normalize-punctuation.perl'
TOKENIZER = MOSES_SCRIPTS / 'tokenizer' / 'tokenizer.perl'
CLEAN_CORPUS = MOSES_SCRIPTS / 'training' / 'clean-corpus-n.perl'
TRAIN_TRUECASER = MOSES_SCRIPTS / 'recaser' / 'train-truecaser.perl'
TRUECASE = MOSES_SCRIPTS / 'recaser' / 'truecase.perl'
MOSES_SGM = MOSES_SCRIPTS / 'generic' / 'input-from-sgm.perl'

# Data dir
LATVIAN_DATA_DIR = PROJECT_ROOT / 'data'
FRENCH_DATA_DIR = PROJECT_ROOT / 'data' / 'fr'
RUSSIAN_DATA_DIR = PROJECT_ROOT / 'data' / 'ru'
