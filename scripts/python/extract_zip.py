import sys
import zipfile

# extract all zip files provided in arguments to cwd
for file in sys.argv[1:]:
    sys.stderr.write(f"unzipping {file} \n")
    with zipfile.ZipFile(file, 'r') as f:
        f.extractall()
