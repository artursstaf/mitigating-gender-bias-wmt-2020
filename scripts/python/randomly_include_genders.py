import argparse

import numpy as np
from tqdm import tqdm


def randomly_include(genders):
    with open(genders) as f:
        genders = f.read().strip().split('\n')

    genders = [line.split() for line in genders]

    randomized_gender_lines = []
    for line, threshold in tqdm(zip(genders, np.random.random(len(genders)))):
        randomized_gender_line = []

        for word, include_word_random_number in zip(line, np.random.random(len(line))):
            if include_word_random_number <= threshold:
                randomized_gender_line.append(word)
            else:
                randomized_gender_line.append('U')

        randomized_gender_lines.append(randomized_gender_line)

    print('\n'.join([' '.join(line) for line in randomized_gender_lines]))


def main():
    parser = argparse.ArgumentParser(
        description="Randomly include true genders for each sentence based on random threshold(for each  sentence)")
    parser.add_argument("--genders", help="File that contains genders")

    args = parser.parse_args()
    randomly_include(args.genders)


if __name__ == "__main__":
    main()
