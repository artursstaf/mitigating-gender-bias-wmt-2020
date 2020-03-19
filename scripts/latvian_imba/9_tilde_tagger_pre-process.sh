#!/bin/bash
set -eu
DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$DIR")")
PYTHON_SCR="$PROJECT_ROOT"/scripts/python
cd "$PROJECT_ROOT"

LANG=lv_imba
EXPERIMENT=tilde_tagger
VALIDATION=newsdev2017
CORPUS=train
CHUNK_SIZE=$1

mkdir -p data/"$LANG"/"$EXPERIMENT"
(
  cd data/"$LANG"/"$EXPERIMENT"

  for file in $CORPUS $VALIDATION; do

    ln -sf ../"$file".tc."$LANG" "$file".tc."$LANG"
    ln -sf ../"$file".tc.BPE."$LANG" "$file".tc.BPE."$LANG"

    ln -sf ../"$file".tc.en "$file".tc.en
    ln -sf ../"$file".tc.BPE.en "$file".tc.BPE.en

    rm -f "$file.genders.$LANG"?*
    rm -f "$file.tc.$LANG"?*

    # Split file and process in parallel for efficiency reasons
    split "$file".tc."$LANG" "$file".tc."$LANG" --numeric-suffixes=1 -n l/"$CHUNK_SIZE"

    for i in $(seq 1 "$CHUNK_SIZE"); do

      bash /home/TILDE.LV/marcis.pinnis/tools/wmt-factorizer/run-lv-factorizer.sh \
        <"$file".tc."$LANG"0"$i" |
        python "$PYTHON_SCR"/tilde_tagger_get_genders.py \
          >"$file".genders."$LANG"0"$i" &

    done
    wait

    # Combine chunks back
    cat "$file.genders.$LANG"?* >"$file".genders."$LANG"
    rm "$file.genders.$LANG"?*
    rm "$file.tc.$LANG"?*

    # Generate word alignments
    alignments_folder=../../alignments
    paste -d "|" "$file".tc."$LANG" "$file".tc.en | sed 's/|/ ||| /g' >$alignments_folder/"$file"."$LANG"-en.txt

    if [[ "$file" == "$CORPUS" ]]; then
      #train alignment model
      ../../../tools/fast_align/build/fast_align -d -o -v \
        -p $alignments_folder/"$file"."$LANG"-en.align.model \
        -i $alignments_folder/"$file"."$LANG"-en.txt \
        >$alignments_folder/"$file"."$LANG"-en.align \
        2>$alignments_folder/"$file"."$LANG"-en.align.debug
    else
      # Extract hyper parameters and apply model to validation set
      m=$(grep -o -P "(?<=source length \* )[0-9]?\.[0-9]+" $alignments_folder/"$CORPUS"."$LANG"-en.align.debug)
      echo "Source-target length ratio $m"
      T=$(grep -o -P "(?<=final tension: )[0-9]?\.[0-9]+" $alignments_folder/"$CORPUS"."$LANG"-en.align.debug | tail -1)
      echo "Final tension $T"

      ../../../tools/fast_align/build/fast_align -d -o -v \
        -m "$m" -T "$T" \
        -f $alignments_folder/"$CORPUS"."$LANG"-en.align.model \
        -i $alignments_folder/"$file"."$LANG"-en.txt |
        awk -F ' \\|\\|\\| ' '{print $3}' >$alignments_folder/"$file"."$LANG"-en.align
    fi

    # Get EN genders by aligning $LANG genders to EN corpus
    python "$PYTHON_SCR"/align_genders.py \
      --target "$file".tc.en \
      --source_genders "$file".genders."$LANG" \
      --source_target_alignment $alignments_folder/"$file"."$LANG"-en.align \
      >"$file".genders.en

    # Get randomized genders
    python "$PYTHON_SCR"/randomly_include_genders.py \
      --genders "$file".genders.en \
      >"$file".threshold-genders.en

    python "$PYTHON_SCR"/genders_bpe.py \
      --genders "$file".genders.en \
      --bpe_sentences "$file".tc.BPE.en \
      >"$file".genders.BPE.en

    # Get corresponding BPE format for genders
    python "$PYTHON_SCR"/genders_bpe.py \
      --genders "$file".threshold-genders.en \
      --bpe_sentences "$file".tc.BPE.en \
      >"$file".threshold-genders.BPE.en

    # Format data for  experiment
    sed 's/[MFN]/U/g' <"$file".threshold-genders.BPE.en >"$file".u-genders.BPE.en
    cat "$file".threshold-genders.BPE.en "$file".u-genders.BPE.en >"$file".genders.final.en
    cat "$file".tc.BPE.en "$file".tc.BPE.en >"$file".final.en
    cat "$file".tc.BPE."$LANG" "$file".tc.BPE."$LANG" >"$file".final."$LANG"
  done
)

# Sockeye prepare data
(
  cd data/"$LANG"
  python -m sockeye.prepare_data -s "$EXPERIMENT"/"$CORPUS".final.en \
    -t "$EXPERIMENT"/"$CORPUS".final."$LANG" \
    -o nmt_"$LANG"_"$EXPERIMENT"_prepare_data \
    --source-factors "$EXPERIMENT"/"$CORPUS".genders.final.en \
    --num-words 50000 \
    --max-seq-len 128 \
    --shared-vocab
)
