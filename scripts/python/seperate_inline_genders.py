import sys

# Separate inline genders into separate file
# Example: The boss|M and the secretary|F -> U M U U F

with open(sys.argv[1], 'w') as out1, open(sys.argv[2], 'w') as out2:
    for line in sys.stdin:
        for token in line.strip().split():
            splits = token.split('|')
            if len(splits) == 1:
                out1.write(splits[0] + ' ')
                out2.write('U ')
            else:
                word, gender = token.split('|')
                out1.write(word + ' ')
                out2.write(gender + ' ')
        out1.write('\n')
        out2.write('\n')
