#!/bin/bash
set -e
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
TOOLS=$PROJECT_ROOT/tools
cd "$PROJECT_ROOT"

LANG=$1
EXPERIMENT=$2
CORPUS=$3
VALIDATION=$4
DEVICE_IDS="$5"
WMT_SET=$6

mkdir -p data/dev_translations/"$LANG"/"$EXPERIMENT"
mkdir -p evaluation_logs/"$LANG"/"$EXPERIMENT"

(
  cd data/"$LANG"/"$EXPERIMENT"
  alignments_folder=../../alignments

  ln -sf ../"$VALIDATION".tc.en  "$VALIDATION".tc.en
  ln -sf ../"$VALIDATION".tc.$LANG  "$VALIDATION".tc.$LANG
  ln -sf ../"$VALIDATION".tc.BPE.en  "$VALIDATION".tc.BPE.en

  # Prepare reference
  sacrebleu -t $WMT_SET -l en-${LANG:0:2} --echo ref > $WMT_SET.ref
  cat $WMT_SET.ref | perl "$TOOLS"/moses-scripts/scripts/tokenizer/normalize-punctuation.perl -l ${LANG:0:2} > $WMT_SET.normal.ref

  python $PROJECT_ROOT/scripts/python/generate_genders.py --lang "${LANG:0:2}" --source "$VALIDATION".tc."$LANG" \
        --output "$VALIDATION".genders."$LANG"

  paste -d "|" "$VALIDATION".tc."$LANG" "$VALIDATION".tc.en | sed 's/|/ ||| /g' >$alignments_folder/"$VALIDATION"."$LANG"-en.txt
  # Extract hyper parameters and apply model to validation set

  m=$(grep -o -P "(?<=source length \* )[0-9]?\.[0-9]+" $alignments_folder/"$CORPUS"."${LANG:0:7}"-en.align.debug)
  echo "Source-target length ratio $m"
  T=$(grep -o -P "(?<=final tension: )[0-9]?\.[0-9]+" $alignments_folder/"$CORPUS"."${LANG:0:7}"-en.align.debug | tail -1)
  echo "Final tension $T"

  "$PROJECT_ROOT"/tools/fast_align/build/fast_align -d -o -v \
    -m "$m" -T "$T" \
    -f $alignments_folder/"$CORPUS"."${LANG:0:7}"-en.align.model \
    -i $alignments_folder/"$VALIDATION"."$LANG"-en.txt |
    awk -F ' \\|\\|\\| ' '{print $3}' >$alignments_folder/"$VALIDATION"."$LANG"-en.align
    
  python ../../../scripts/python/align_genders.py \
  --target "$VALIDATION".tc.en \
  --source_genders "$VALIDATION".genders."$LANG" \
  --source_target_alignment $alignments_folder/"$VALIDATION"."$LANG"-en.align \
  >"$VALIDATION".genders.en

  python ../../../scripts/python/genders_bpe.py \
  --genders "$VALIDATION".genders.en \
  --bpe_sentences "$VALIDATION".tc.BPE.en \
  >"$VALIDATION".genders.BPE.en

  sed 's/[MFN]/U/g' <"$VALIDATION".genders.BPE.en >"$VALIDATION".u-genders.BPE.en
)

# Generate random genders
(
  cd data/"$LANG"/"$EXPERIMENT"
  python ../../../scripts/python/random_genders.py --genders "$VALIDATION".tc.en >g.tmp
  python ../../../scripts/python/genders_bpe.py --genders g.tmp --bpe_sentences "$VALIDATION".tc.BPE.en >"$VALIDATION".r-genders.BPE.en
  rm g.tmp
)

for type in "true " "unkown u-" "random r-"; do
  set -- $type

  python -m sockeye.translate \
    -m models/"$LANG"/nmt_"$LANG"_"$EXPERIMENT" \
    --input-factors data/"$LANG"/"$EXPERIMENT"/"$VALIDATION"."$2"genders.BPE.en \
    --input data/$LANG/"$VALIDATION".tc.BPE.en \
    --device-ids $DEVICE_IDS >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc.BPE."$LANG"
    sed -r 's/@@( |$)//g' < data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc.BPE."$LANG" >data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc."$LANG"

    cat data/dev_translations/"$LANG"/"$EXPERIMENT"/"$1"_"$VALIDATION".tc."$LANG" | perl "$TOOLS"/moses-scripts/scripts/recaser/detruecase.perl | perl "$TOOLS"/moses-scripts/scripts/tokenizer/detokenizer.perl -l ${LANG:0:2} |
        sacrebleu data/"$LANG"/"$EXPERIMENT"/$WMT_SET.normal.ref > evaluation_logs/"$LANG"/"$EXPERIMENT"/bleu_test_"$1".txt
done


