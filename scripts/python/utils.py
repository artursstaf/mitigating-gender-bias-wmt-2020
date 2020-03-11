import gzip

import math
import regex


def concatenate(output_file, *input_files):
    with open(str(output_file), 'w', encoding='utf-8') as out:
        for file in sorted(input_files):
            print(f'concatenating: {file}')
            with open(str(file), 'r', encoding='utf-8') as input_file:
                for line in input_file:
                    out.write(line)


def chunk(num_chunks, input_data):
    chunk_size = math.ceil(len(input_data) / num_chunks)
    for i in range(num_chunks):
        yield input_data[i * chunk_size: (i + 1) * chunk_size]


def normalize_line_ending(filename):
    with open(str(filename), 'rb') as f:
        content = f.read()

    for pattern, replace_with in [(b"\\r[^\\n]", b" "), (b"\\r\\n", b"\\n")]:
        content = regex.sub(pattern, replace_with, content)

    with open(str(filename), 'wb') as f:
        f.write(content)


def gunzip(filename):
    with gzip.open(str(filename), 'rb') as f:
        content = f.read()
    with open(str(filename, 'wb')) as f:
        f.write(content)
