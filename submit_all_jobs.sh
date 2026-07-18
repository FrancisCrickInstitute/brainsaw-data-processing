#!/bin/bash

usage() {
    echo "Usage: ./submit_all_jobs.sh -i <input_base_dir> -c <converted_base_dir> -s <stitched_base_dir> -j <fiji_path> [-l label_filter] [-f array_indices] [-n section_indices] [-x]"
    echo "  -i  Input base directory (required)"
    echo "  -c  Converted files base directory (required)"
    echo "  -s  Stitched output base directory (required)"
    echo "  -j  Path to FIJI executable (required)"
    echo "  -l  Only process subdirectories containing this text (optional, e.g. 'hml_old')"
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
LABEL_FILTER=""
ARRAY_INDICES=""
SECTION_INDICES=""
CLEANUP=false

while getopts "i:c:s:j:l:f:n:x" opt; do
    case $opt in
        i) INPUT_BASE_DIR="$OPTARG" ;;
        c) CONVERTED_BASE_DIR="$OPTARG" ;;
        s) STITCHED_BASE_DIR="$OPTARG" ;;
        j) FIJI_PATH="$OPTARG" ;;
        l) LABEL_FILTER="$OPTARG" ;;
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

# Build list of directories to process, optionally filtered by label
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

    # Skip directories that don't contain the label filter string
    if [ -n "$LABEL_FILTER" ] && [[ "$INPUT_DIR" != *"$LABEL_FILTER"* ]]; then
        echo "Skipping $INPUT_DIR - does not match label filter '$LABEL_FILTER'"
        continue
    fi

    mapfile -t input_files < <(printf '%s\n' "$INPUT_DIR"/*.tif | sort)
    num_files=${#input_files[@]}
    if [ "$num_files" -eq 0 ]; then
        echo "Skipping $INPUT_DIR - no .tif tiles found (not a section directory)"
        continue
    fi

    dirname=$(basename "$INPUT_DIR")
    CONVERTED_DIR="${CONVERTED_BASE_DIR}/${dirname}"
    STITCHED_DIR="${STITCHED_BASE_DIR}/${dirname}-fused"

    # Resume support: on a default (unfiltered) run, a section whose fused
    # output already exists is fully done - skip the whole chain for it.
    if [ -z "$ARRAY_INDICES" ] && ls "$STITCHED_DIR"/*.tif >/dev/null 2>&1; then
        echo "Skipping $INPUT_DIR - fused output already exists in $STITCHED_DIR"
        continue
    fi

    if [ -n "$ARRAY_INDICES" ]; then
        # Explicit -f always reprocesses exactly what was asked for, regardless
        # of what's already been converted.
        array_spec="$ARRAY_INDICES"
    else
        # Resume support: only (re)convert tiles that aren't already converted.
        missing_indices=()
        for ((i = 0; i < num_files; i++)); do
            base=$(basename "${input_files[$i]}" .tif)
            [ -f "${CONVERTED_DIR}/${base}.ome.tif" ] || missing_indices+=("$i")
        done
        if [ "${#missing_indices[@]}" -eq 0 ]; then
            array_spec=""
        else
            array_spec=$(IFS=,; echo "${missing_indices[*]}")
        fi
    fi

    positions_job_id=""
    if [ -f "${INPUT_DIR}/tilePositions.csv" ]; then
        echo "Skipping positions job for $INPUT_DIR - tilePositions.csv already exists"
    else
        positions_job_id=$(sbatch --export=INPUT_DIR="$INPUT_DIR" \
                                  --parsable \
                                  prepare_positions.sh)
        echo "Submitted positions job $positions_job_id for $INPUT_DIR"
    fi

    conv_job_id=""
    if [ -z "$array_spec" ]; then
        echo "Skipping conversion for $INPUT_DIR - all tiles already converted in $CONVERTED_DIR"
    else
        conv_args=(--array="$array_spec" --export=INPUT_DIR="$INPUT_DIR",OUTPUT_DIR="$CONVERTED_DIR" --parsable)
        [ -n "$positions_job_id" ] && conv_args+=(--dependency=afterok:"$positions_job_id")
        conv_job_id=$(sbatch "${conv_args[@]}" ome_convert.sh)
        echo "Submitted conversion job $conv_job_id for $INPUT_DIR (tiles: $array_spec)"
    fi

    stitch_args=(--export=INPUT_DIR="$CONVERTED_DIR",OUTPUT_DIR="$STITCHED_DIR",FIJI_PATH="$FIJI_PATH" --parsable)
    [ -n "$conv_job_id" ] && stitch_args+=(--dependency=afterok:"$conv_job_id")
    stitch_job_id=$(sbatch "${stitch_args[@]}" run_bigstitcher.sh)
    echo "Submitted stitching job $stitch_job_id for $CONVERTED_DIR"

    if [ "$CLEANUP" = true ]; then
        cleanup_job_id=$(sbatch --dependency=afterany:$stitch_job_id \
                                --parsable \
                                --job-name=brainsaw-cleanup \
                                --ntasks=1 \
                                --mem=1G \
                                --partition=ncpu \
                                --wrap="if ls '$STITCHED_DIR'/*.tif >/dev/null 2>&1; then
                                    echo 'Fused output found in $STITCHED_DIR - removing converted files in $CONVERTED_DIR';
                                    rm -rf '$CONVERTED_DIR' && echo 'Cleanup successful' || echo 'Cleanup failed - rm exited with error';
                                else
                                    echo 'Fused output not found in $STITCHED_DIR - skipping cleanup to avoid data loss';
                                fi")
        echo "Submitted cleanup job $cleanup_job_id for $CONVERTED_DIR"
    fi

done
