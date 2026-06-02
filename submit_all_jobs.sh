#!/bin/bash

usage() {
    echo "Usage: ./submit_all_jobs.sh -i <input_base_dir> -c <converted_base_dir> -s <stitched_base_dir> -j <fiji_path> [-f array_indices] [-n section_indices] [-x]"
    echo "  -i  Input base directory (required)"
    echo "  -c  Converted files base directory (required)"
    echo "  -s  Stitched output base directory (required)"
    echo "  -j  Path to FIJI executable (required)"
    echo "  -f  File indices to process (optional, e.g. '246,247,248')"
    echo "  -n  Section indices to process (optional, e.g. '1,3,5')"
    echo "  -x  Delete converted files after successful stitching (optional)"
    exit 1
}

# Parse flags
INPUT_BASE_DIR=""
CONVERTED_BASE_DIR=""
STITCHED_BASE_DIR=""
FIJI_PATH=""
ARRAY_INDICES=""
SECTION_INDICES=""
CLEANUP=false

while getopts "i:c:s:j:f:n:x" opt; do
    case $opt in
        i) INPUT_BASE_DIR="$OPTARG" ;;
        c) CONVERTED_BASE_DIR="$OPTARG" ;;
        s) STITCHED_BASE_DIR="$OPTARG" ;;
        j) FIJI_PATH="$OPTARG" ;;
        f) ARRAY_INDICES="$OPTARG" ;;
        n) SECTION_INDICES="$OPTARG" ;;
        x) CLEANUP=true ;;
        *) usage ;;
    esac
done

# Check required arguments
if [ -z "$INPUT_BASE_DIR" ] || [ -z "$CONVERTED_BASE_DIR" ] || [ -z "$STITCHED_BASE_DIR" ] || [ -z "$FIJI_PATH" ]; then
    echo "Error: -i, -c, -s and -j are required"
    usage
fi

# Build list of directories to process
if [ -n "$SECTION_INDICES" ]; then
    dirs=()
    IFS=',' read -ra sections <<< "$SECTION_INDICES"
    for i in "${sections[@]}"; do
        dirs+=("$(find "$INPUT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort | sed -n "${i}p")")
    done
else
    mapfile -t dirs < <(find "$INPUT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi

for INPUT_DIR in "${dirs[@]}"; do

    dirname=$(basename "$INPUT_DIR")
    CONVERTED_DIR="${CONVERTED_BASE_DIR}/${dirname}"
    STITCHED_DIR="${STITCHED_BASE_DIR}/${dirname}-fused"

    if [ -n "$ARRAY_INDICES" ]; then
        array_spec="$ARRAY_INDICES"
    else
        num_files=$(ls "$INPUT_DIR"/*.tif | wc -l)
        array_spec="0-$((num_files - 1))"
    fi

    conv_job_id=$(sbatch --array="$array_spec" \
                         --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$CONVERTED_DIR" \
                         --parsable \
                         ome_convert.sh)
    echo "Submitted conversion job $conv_job_id for $INPUT_DIR"

    stitch_job_id=$(sbatch --dependency=afterok:$conv_job_id \
                           --export=INPUT_DIR="$CONVERTED_DIR",OUTPUT_DIR="$STITCHED_DIR",FIJI_PATH="$FIJI_PATH" \
                           --parsable \
                           run_bigstitcher.sh)
    echo "Submitted stitching job $stitch_job_id for $CONVERTED_DIR"

    if [ "$CLEANUP" = true ]; then
        cleanup_job_id=$(sbatch --dependency=afterany:$stitch_job_id \
                                --parsable \
                                --job-name=brainsaw-cleanup \
                                --ntasks=1 \
                                --mem=1G \
                                --partition=ncpu \
                                --wrap="if [ -d '$STITCHED_DIR' ] && [ \"\$(ls '$STITCHED_DIR' | wc -l)\" -gt 0 ]; then
                                    echo 'Stitching output found in $STITCHED_DIR - removing converted files in $CONVERTED_DIR';
                                    rm -rf '$CONVERTED_DIR' && echo 'Cleanup successful' || echo 'Cleanup failed - rm exited with error';
                                else
                                    echo 'Stitching output not found in $STITCHED_DIR - skipping cleanup to avoid data loss';
                                fi")
        echo "Submitted cleanup job $cleanup_job_id for $CONVERTED_DIR"
    fi

done
