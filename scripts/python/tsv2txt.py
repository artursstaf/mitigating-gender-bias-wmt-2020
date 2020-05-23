import argparse

from pathlib import Path


def tsv2txt(tsv, left, right):
    tsv = Path(tsv)
    with tsv.open('r') as tsv_file, open(tsv.stem + '.' + left, 'w') as left, open(tsv.stem + '.' + right,
                                                                                   'w') as right:
        for line in tsv_file:
            splits = line.strip().split("\t")
            if line.strip() == "" or len(splits) != 2:
                continue
            left.write(splits[0].strip() + '\n')
            right.write(splits[1].strip() + '\n')


def main():
    parser = argparse.ArgumentParser(description="Read TSV corpus and split into source target file")
    parser.add_argument("tsv", help="Tab separated corpus")
    parser.add_argument("left_lang", help="Lang for left side sentences")
    parser.add_argument("right_lang", help="Lang for right side sentences")

    args = parser.parse_args()
    tsv2txt(args.tsv, args.left_lang, args.right_lang)


if __name__ == "__main__":
    main()
