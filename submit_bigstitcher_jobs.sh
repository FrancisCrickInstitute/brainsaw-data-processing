#!/bin/bash

# Usage: ./submit_bigstitcher_jobs.sh <input_base_dir> <output_base_dir>
INPUT_BASE_DIR=${1:?"Error: input base directory must be specified"}
OUTPUT_BASE_DIR=${2:?"Error: output base directory must be specified"}

# Loop over all subdirectories in the input base directory, sorted
for INPUT_DIR in $(find "$INPUT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort); do

    # Derive the output directory name from the input directory name
    dirname=$(basename "$INPUT_DIR")
    OUTPUT_DIR="${OUTPUT_BASE_DIR}/${dirname}-fused"

    echo "Submitting stitching job for $INPUT_DIR"
    sbatch --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$OUTPUT_DIR" \
           run_bigstitcher.sh
done