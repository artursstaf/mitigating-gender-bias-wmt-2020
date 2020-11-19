import argparse
import sys
from pathlib import Path

# AllenNLP
# !pip install allennlp==1.0.0 allennlp-models==1.0.0
from allennlp.predictors.predictor import Predictor
# ! pip install scikit-learn
from sklearn.metrics import *
from tqdm import tqdm


def extract_genders(wino_mt_en, wino_mt_genders):
    wino_mt_preprop = Path(wino_mt_en).read_text().strip().split('\n')

    predictor = Predictor.from_path(
        "https://storage.googleapis.com/allennlp-public-models/coref-spanbert-large-2020.02.27.tar.gz")

    docs_genders = ""
    for text in tqdm(wino_mt_preprop[:]):

        result = predictor.predict(
            document=text
        )

        word_genders = ['U'] * len(result['document'])
        for i, cluster in enumerate(result['clusters']):

            mark = None
            # Find pronoun
            for span_start, span_end in cluster:
                # assume is in span of size 1
                if span_end - span_start > 0:
                    continue

                word = result['document'][span_start].lower()

                if word in {"he", "his", "him"}:
                    mark = 'M'
                    break
                elif word in {"she", "her", "hers"}:
                    mark = 'F'
                    break

            if mark is None:
                continue

            for span_start, span_end in cluster:
                for i in range(span_start, span_end + 1):
                    word_genders[i] = mark

        doc_token_it = iter(zip(result['document'], word_genders))

        # Find matching tokens
        sentence_genders = []
        for sent in text.strip().split('\n'):
            token_genders = []
            for token in sent.strip().split(' '):
                doc_token, doc_gender = next(doc_token_it)
                while doc_token == '\n':
                    doc_token, doc_gender = next(doc_token_it)

                if token == doc_token:
                    token_genders.append(doc_gender)
                    continue

                # tokens differ start merging
                mark = 'U'
                try:
                    while doc_token != token:
                        next_doc_token, next_doc_gender = next(doc_token_it)
                        while doc_token == '\n':
                            doc_token, doc_gender = next(doc_token_it)
                        doc_token += next_doc_token
                        if next_doc_gender != 'U':
                            mark = next_doc_gender
                except Exception as e:
                    sys.stderr.write(f"Token: {token}\n")
                    sys.stderr.write(f"DocTokten: {doc_token}\n")
                    raise e
                token_genders.append(mark)
            sys.stdout.write(' '.join(token_genders) + '\n')
            sentence_genders.append(' '.join(token_genders))
        sentence_genders = '\n'.join(sentence_genders)
        docs_genders += sentence_genders.strip() + "\n"

    # Evaluate produced gender marks vs gold annotations
    if wino_mt_genders:
        gold_genders = Path(wino_mt_genders)

        y_true = [g.split() for g in gold_genders.read_text().strip().split('\n')]
        y_pred = [g.split() for g in docs_genders.strip().split('\n')]

        # Flatten
        y_true = [gen for line in y_true for gen in line]
        y_pred = [gen for line in y_pred for gen in line]

        evaluation = precision_recall_fscore_support(y_true, y_pred, labels=['M', 'F', 'U'])
        sys.stderr.write(f"M p:{evaluation[0][0]} r:{evaluation[1][0]} f1:{evaluation[2][0]}\n")
        sys.stderr.write(f"F p:{evaluation[0][1]} r:{evaluation[1][1]} f1:{evaluation[2][1]}\n")


def main():
    parser = argparse.ArgumentParser(description="Create genders file with AllenNLP coreference resolution tool")
    parser.add_argument("--wino_mt_en", help="Pre-processed EN sentences from WinoMT", required=True)
    parser.add_argument("--wino_mt_genders", help="Extracted golden WinoMT gender marks  (Used for evaluation)")

    args = parser.parse_args()
    extract_genders(args.wino_mt_en, args.wino_mt_genders)


if __name__ == "__main__":
    main()
