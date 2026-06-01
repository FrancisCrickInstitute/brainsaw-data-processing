#!/bin/bash

# Usage: ./submit_ome_convert_jobs.sh <input_base_dir> <output_base_dir> [array_indices]
INPUT_BASE_DIR=${1:?"Error: input base directory must be specified"}
OUTPUT_BASE_DIR=${2:?"Error: output base directory must be specified"}
ARRAY_INDICES=${3:-""}

# Loop over all subdirectories in the input base directory, sorted
for INPUT_DIR in $(find "$INPUT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort); do

    # Derive the output directory name from the input directory name
    dirname=$(basename "$INPUT_DIR")
    OUTPUT_DIR="${OUTPUT_BASE_DIR}/${dirname}"

    if [ -n "$ARRAY_INDICES" ]; then
        array_spec="$ARRAY_INDICES"
    else
        num_files=$(ls "$INPUT_DIR"/*.tif | wc -l)
        array_spec="0-$((num_files - 1))"
    fi

    echo "Submitting conversion jobs for $INPUT_DIR"
    sbatch --array="$array_spec" \
           --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$OUTPUT_DIR" \
           ome_convert.sh
done