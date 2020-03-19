import sys

import tqdm

sys.stderr.write("extracting genders from tags \n")

for line in tqdm.tqdm(sys.stdin):
    tags = [word.split('|')[2] for word in line.strip().split(' ')]
    genders = [tag[2].upper() if tag[2] != '-' else 'U' for tag in tags]
    sys.stdout.write(' '.join(genders) + '\n')
