#!/bin/bash

DATA="."


transform_to_pmltq () {
  DIR=$1
  DIRECTORY=$2
  echo "Adding information to files for searching in PMLTQ in ${DIR}..."
  ORIG_DIR=`pwd`
  cd ${DIR}
  btred -I ${ORIG_DIR}/_transform_to_pmltq.ntred *.t.gz >_transform_to_pmltq.log 2>&1 -o ${DIRECTORY} --
  rm -f *~
  cd ${ORIG_DIR}
  echo "...done"
}

transform_to_pmltq "${DATA}/train-1" "train-1"
transform_to_pmltq "${DATA}/train-2" "train-2"
transform_to_pmltq "${DATA}/train-3" "train-3"
transform_to_pmltq "${DATA}/train-4" "train-4"
transform_to_pmltq "${DATA}/train-5" "train-5"
transform_to_pmltq "${DATA}/train-6" "train-6"
transform_to_pmltq "${DATA}/train-7" "train-7"
transform_to_pmltq "${DATA}/train-8" "train-8"
transform_to_pmltq "${DATA}/dtest"   "dtest"
transform_to_pmltq "${DATA}/etest"   "etest"
