import argparse
import os
import sys

import tqdm


def align_bpe(genders, sentences):
    sys.stderr.write(f'currently in {os.getcwd()} \n')
    sys.stderr.write(f'genders file: {genders} \n')
    sys.stderr.write(f'sentences file: {sentences} \n')

    with open(genders, 'r') as f:
        genders = f.read().strip().split('\n')
    with open(sentences, 'r') as f:
        sentences = f.read().strip().split('\n')

    aligned_genders = []
    for sent, gend in tqdm.tqdm(zip(sentences, genders)):
        sent = sent.strip()
        gend = gend.strip()
        aligned_sentence_genders = []
        gend_it = iter(enumerate(gend.split(' ')))
        i, cur_gender = next(gend_it)

        for word in sent.split(' '):
            assert cur_gender is not None
            aligned_sentence_genders.append(cur_gender)
            if not word.endswith("@@"):
                i, cur_gender = next(gend_it, (float('inf'), None))
        aligned_genders.append(aligned_sentence_genders)

    print('\n'.join([' '.join(line) for line in aligned_genders]))


def main():
    parser = argparse.ArgumentParser(description="Copies gender factors to reflect corresponding BPE parts")
    parser.add_argument("--genders", help="File that contains genders")
    parser.add_argument("--bpe_sentences", help="Byte pair encoded sentences")

    args = parser.parse_args()
    align_bpe(args.genders, args.bpe_sentences)


if __name__ == "__main__":
    main()
