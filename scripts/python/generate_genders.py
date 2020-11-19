import argparse
from pathlib import Path

import stanza
import tqdm

default_package = {
    'lt': 'alksnis',
    'lv': 'lvtb',
    'fr': 'gsd',
    'ru': 'SynTagRus',
    'de': 'hdt'
}

def gen_genders(lang, source, output):
    with open(source, 'r') as f:
        source = f.read().strip().split('\n')

    # download models if necessary
    nlp_resources = Path.home() / 'stanza_resources'
    dirs = [x for x in nlp_resources.iterdir() if x.is_dir()]

    if not any(lang in d.name for d in dirs):
        stanza.download(lang, package=default_package[lang], dir=str(nlp_resources))

    config = {
        'processors': 'tokenize,pos',
        'tokenize_pretokenized': True,
        'lang': lang,
        'package': default_package[lang]
    }

    nlp = stanza.Pipeline(**config)

    genders = []
    for line in tqdm.tqdm(source):
        if line.isspace() or line is None or len(line) == 0:
            continue

        doc = nlp(line)
        for tok in doc.sentences[0].words:
            key = 'Gender='
            if tok.feats is None or tok.feats.find(key) == -1:
                gender = 'U '
            else:
                offset = tok.feats.find(key)
                gender = tok.feats[offset + len(key): offset + len(key) + 1] + ' '
            genders.append(gender)
        genders.append('\n')

    with open(output, 'w') as f:
        f.write(''.join(genders).strip())
        f.write('\n')


def main():
    parser = argparse.ArgumentParser(
        description="Extract gender per token using StanfordNLP")
    parser.add_argument("--lang", help="Language used", required=True)
    parser.add_argument("--source", help="Source file", required=True)
    parser.add_argument("--output", help="Output file", required=True)

    args = parser.parse_args()
    gen_genders(args.lang, args.source, args.output)


if __name__ == "__main__":
    main()
