#!/bin/bash

# Usage: ./submit_all_jobs.sh <input_base_dir> <converted_base_dir> <stitched_base_dir> [array_indices]
INPUT_BASE_DIR=${1:?"Error: input base directory must be specified"}
CONVERTED_BASE_DIR=${2:?"Error: converted base directory must be specified"}
STITCHED_BASE_DIR=${3:?"Error: stitched base directory must be specified"}
ARRAY_INDICES=${4:-""}

# Optional cleanup flag
CLEANUP=${CLEANUP:-false}

for INPUT_DIR in $(find "$INPUT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort); do

    dirname=$(basename "$INPUT_DIR")
    CONVERTED_DIR="${CONVERTED_BASE_DIR}/${dirname}"
    STITCHED_DIR="${STITCHED_BASE_DIR}/${dirname}-fused"

    if [ -n "$ARRAY_INDICES" ]; then
        array_spec="$ARRAY_INDICES"
    else
        num_files=$(ls "$INPUT_DIR"/*.tif | wc -l)
        array_spec="0-$((num_files - 1))"
    fi

    # Submit conversion job array
    conv_job_id=$(sbatch --array="$array_spec" \
                         --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$CONVERTED_DIR" \
                         --parsable \
                         ome_convert.sh)
    echo "Submitted conversion job $conv_job_id for $INPUT_DIR"

    # Submit stitching job, dependent on conversion completing successfully
    stitch_job_id=$(sbatch --dependency=afterok:$conv_job_id \
                           --export=INPUT_DIR="$CONVERTED_DIR",OUTPUT_DIR="$STITCHED_DIR" \
                           --parsable \
                           run_bigstitcher.sh)
    echo "Submitted stitching job $stitch_job_id for $CONVERTED_DIR"

    # Optionally submit cleanup job, dependent on stitching completing successfully
    if [ "$CLEANUP" = true ]; then
        cleanup_job_id=$(sbatch --dependency=afterok:$stitch_job_id \
                                --parsable \
                                --job-name=brainsaw-cleanup \
                                --ntasks=1 \
                                --mem=1G \
                                --partition=ncpu \
                                --wrap="rm -rf '$CONVERTED_DIR'")
        echo "Submitted cleanup job $cleanup_job_id for $CONVERTED_DIR"
    fi

done