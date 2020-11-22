import argparse
import sys
from pathlib import Path

import neuralcoref
import spacy
import tqdm
from spacy.tokenizer import Tokenizer


def extract_genders(wino_mt_en):
    wino_mt_preprop = Path(wino_mt_en).read_text().strip().split('\n')
    nlp = spacy.load('en')
    nlp.tokenizer = Tokenizer(nlp.vocab)
    neuralcoref.add_to_pipe(nlp)

    def to_str_list(x):
        return [str(z) for z in x]

    for sentence in tqdm.tqdm(wino_mt_preprop):
        sentence = sentence.replace("&apos;", "'")
        doc = nlp(sentence)
        token_genders = ['U'] * (len(sentence.split()))

        for i, token in enumerate(doc):
            if any(len(set(to_str_list(c.mentions)).intersection({"she", "her", "hers"})) != 0 for c in
                   token._.coref_clusters):
                mark = "F"
            elif any(len(set(to_str_list(c.mentions)).intersection({"he", "his", "him"})) != 0 for c in
                     token._.coref_clusters):
                mark = "M"
            else:
                mark = "U"
            token_genders[i] = mark

        sys.stdout.write(" ".join(token_genders) + "\n")


def main():
    parser = argparse.ArgumentParser(description="Create genders file with AllenNLP coreference resolution tool")
    parser.add_argument("--wino_mt_en", help="Pre-processed EN sentences from WinoMT", required=True)

    args = parser.parse_args()
    extract_genders(args.wino_mt_en)


if __name__ == "__main__":
    main()
