#!/bin/bash

# Usage: ./submit_ome_convert_jobs.sh <input_base_dir> <output_dir> [array_indices]
INPUT_BASE_DIR=${1:?"Error: input base directory must be specified"}
OUTPUT_DIR=${2:?"Error: output directory must be specified"}
ARRAY_INDICES=${3:-""}

# Loop over all input directories, generating zero-padded indices from 0001 to 0176
for i in $(seq -f "%04g" 1 176); do

    INPUT_DIR="${INPUT_BASE_DIR}/CrickSaw_260326_hml_old_young_females_hml-${i}"

    if [ -n "$ARRAY_INDICES" ]; then
        array_spec="$ARRAY_INDICES"
    else
        num_files=$(ls "$INPUT_DIR"/*.tif | wc -l)
        array_spec="0-$((num_files - 1))"
    fi

    sbatch --array="$array_spec" \
           --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$OUTPUT_DIR" \
           ome_convert.sh
done