import argparse


def align_genders(source_genders, target_sentences, alignments):
    with open(source_genders, 'r') as f:
        source_genders = f.read().strip().split('\n')
    with open(alignments, 'r') as f:
        alignments = f.read().strip().split('\n')
    with open(target_sentences, 'r') as f:
        target_sentences = f.read().strip().split('\n')

    aligned_genders = []
    for source, alignment, target in zip(source_genders, alignments, target_sentences):
        source = source.split()
        target = target.split()

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
                genders.append(source[reversed_ind[i]])
            else:
                genders.append('U')

        aligned_genders.append(genders)

    print('\n'.join([' '.join(line) for line in aligned_genders]))


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
