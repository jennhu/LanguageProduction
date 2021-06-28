#!/bin/bash

IN_DIR="../mturk_data/raw"
OUT_DIR="../mturk_data/clean"
mkdir -p ${OUT_DIR}
for HIT_NUM in {1..4}; do
  echo "** HIT ${HIT_NUM} **"
  BATCH="${IN_DIR}/hit${HIT_NUM}.csv"
  VIZ="${OUT_DIR}/hit${HIT_NUM}_viz.html"
  python process_data.py --batch $BATCH --hit $HIT_NUM --out $OUT_DIR
  python viz.py --data $OUT_DIR --hit $HIT_NUM --out $VIZ
done
