import argparse
from datetime import datetime
from pathlib import Path

import stanza

default_package = {
    'lt': 'alksnis',
    'lv': 'lvtb',
    'fr': 'gsd',
    'ru': 'SynTagRus',
    'de': 'hdt'
}


def batch(iterable, n):
    l = len(iterable)
    for ndx in range(0, l, n):
        yield iterable[ndx:min(ndx + n, l)]


def gen_genders(lang, source, output):
    with open(source, 'r') as f:
        source = f.read().strip().split('\n')

    # download models if necessary
    nlp_resources = Path.home() / 'stanza_resources'
    dirs = [x for x in nlp_resources.iterdir() if x.is_dir()]

    if not any(lang in d.name for d in dirs):
        stanza.download(lang, package=default_package[lang], dir=str(nlp_resources))

    config = {
        'use_gpu': True,
        'processors': 'tokenize,pos,lemma',
        'tokenize_pretokenized': True,
        'lang': lang,
        'package': default_package[lang],
        'pos_batch_size': 5000,
        'lemma_batch_size': 1500
    }

    BATCH_SIZE = 5000

    nlp = stanza.Pipeline(**config)

    genders = []
    for index, lines in enumerate(batch(source, BATCH_SIZE)):
        lines = "\n".join(lines)

        start = datetime.now()
        doc = nlp(lines)
        seconds_for_batch = (datetime.now() - start).total_seconds()

        print(
            f"Nr. item: {(index + 1) * BATCH_SIZE}, Seconds for batch: {seconds_for_batch}, sentences per second: {BATCH_SIZE / seconds_for_batch}")

        for sentence in doc.sentences:
            for tok in sentence.words:
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
