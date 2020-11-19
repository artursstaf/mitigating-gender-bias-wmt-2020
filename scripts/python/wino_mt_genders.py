import argparse


def extract_genders(wino_mt, tok_en_sentences):
    with open(wino_mt, 'r') as f:
        wino_mt = f.read().strip().split('\n')
    wino_mt = [i.split('\t') for i in wino_mt]

    with open(tok_en_sentences, 'r') as f:
        tok_en_sentences = f.read().strip().split('\n')
    tok_en_sentences = [i.split() for i in tok_en_sentences]

    gender_mapping = {'neutral': 'U', 'male': 'M', 'female': 'F'}
    sentence_genders = []
    for sentence, wino_mt_entry in zip(tok_en_sentences, wino_mt):
        gender = gender_mapping[wino_mt_entry[0]]
        index = int(wino_mt_entry[1])
        word_genders = []
        for i, word in enumerate(sentence):
            if i == index:
                word_genders.append(gender)
            else:
                word_genders.append('U')

        sentence_genders.append(word_genders)

    print('\n'.join([' '.join(sent) for sent in sentence_genders]))


def main():
    parser = argparse.ArgumentParser(description="Create genders file that matches tokenized WinoMT sentences")
    parser.add_argument("--wino_mt", help="WinoMT dataset")
    parser.add_argument("--tokenized_sentences", help="pre-processed EN sentences from WinoMT")

    args = parser.parse_args()
    extract_genders(args.wino_mt, args.tokenized_sentences)


if __name__ == "__main__":
    main()
