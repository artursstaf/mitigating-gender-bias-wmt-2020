import argparse
import sys

import tqdm


def align_genders(source_genders, target_sentences, alignments):
    source_genders = open(source_genders, 'r', encoding='utf-8-sig')
    alignments = open(alignments, 'r', encoding='utf-8-sig')
    target_sentences = open(target_sentences, 'r', encoding='utf-8-sig')

    for source, alignment, target in tqdm.tqdm(zip(source_genders, alignments, target_sentences)):
        alignment = alignment.strip()
        source = source.strip().split()
        target = list(filter(lambda x: x != '\ufeff', target.strip().split()))

        reversed_ind = {}
        # Reverse alignment indices
        for a in alignment.split():
            s, t = a.split('-')
            assert int(t) not in reversed_ind, \
                "In source-target alignment target word should not point to more than 1 source word"
            reversed_ind[int(t)] = int(s)

        genders = []
        for i, word in enumerate(target):
            if i in reversed_ind:
                try:
                    genders.append(source[reversed_ind[i]])
                except Exception as e:
                    sys.stderr.write(str(e) + '\n')
                    sys.stderr.write(f'Source:{source}\nTarget:{target}')
                    raise e
            else:
                genders.append('U')

        print(' '.join(genders))

    source_genders.close()
    alignments.close()
    target_sentences.close()


def main():
    parser = argparse.ArgumentParser(
        description="Get target genders by providing source genders, s-t alignment and target sentences")
    parser.add_argument("--target", help="File that contains tokenized target sentences")
    parser.add_argument("--source_genders", help="File that contains source genders")
    parser.add_argument("--source_target_alignment", help="File that contains source-target alignment")

    args = parser.parse_args()
    align_genders(args.source_genders, args.target, args.source_target_alignment)


if __name__ == "__main__":
    main()
