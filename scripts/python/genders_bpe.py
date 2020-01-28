import argparse


def align_bpe(genders, sentences):
    with open(genders, 'r') as f:
        genders = f.read().strip().split('\n')
    with open(sentences, 'r') as f:
        sentences = f.read().strip().split('\n')

    aligned_genders = []
    for sent, gend in zip(sentences, genders):
        aligned_sentence_genders = []
        gend_it = iter(gend.split(' '))
        cur_gender = next(gend_it)

        for word in sent.split(' '):
            aligned_sentence_genders.append(cur_gender)
            if not word.endswith("@@"):
                cur_gender = next(gend_it, None)
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
