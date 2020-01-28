import argparse
import random


def generate_random(genders):
    with open(genders, 'r') as f:
        genders = f.read().strip().split('\n')

    new_lines = []
    for line in genders:
        new_line = []
        for _ in line.split():
            new_line.append(random.choice(['U', 'F', 'M']))
        new_lines.append(' '.join(new_line))

    print('\n'.join(new_lines))


def main():
    parser = argparse.ArgumentParser(description="Generate random genders for sentences")
    parser.add_argument("--genders", help="True genders file")

    args = parser.parse_args()
    generate_random(args.genders)


if __name__ == "__main__":
    main()
