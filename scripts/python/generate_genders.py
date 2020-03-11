import argparse

import stanfordnlp
import tqdm
from pathlib import Path


def gen_genders(lang, source, output):
    with open(source, 'r') as f:
        source = f.read().strip().split('\n')

    # download models if necessary
    nlp_resources = Path.home() / 'stanfordnlp_resources'
    dirs = [x for x in nlp_resources.iterdir() if x.is_dir()]
    if not any(lang in d.name for d in dirs):
        stanfordnlp.download(lang, force=True)

    config = {
        'processors': 'tokenize,pos',
        'tokenize_pretokenized': True,
        'lang': lang
    }

    nlp = stanfordnlp.Pipeline(**config)

    genders = []
    for line in tqdm.tqdm(source):
        if line.isspace() or line is None or len(line) == 0:
            continue

        doc = nlp(line)
        for tok in doc.sentences[0].words:
            key = 'Gender='
            offset = tok.feats.find(key)
            if offset == -1:
                gender = 'U '
            else:
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
    parser.add_argument("--chunks", metavar="N", type=int, help="Process in N parallel chunks")
    parser.add_argument("--cuda-devices", type=int, nargs="*", default=[0],
                        help="Distribute chunks across provided CUDA devices")

    args = parser.parse_args()
    gen_genders(args.lang, args.source, args.output)


if __name__ == "__main__":
    main()
