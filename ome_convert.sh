#!/bin/bash
#SBATCH --job-name=brainsaw-conv
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --partition=ncpu
# Note: --array and --export are set dynamically by the submission script

ml pixi

mkdir -p "$OUTPUT_DIR"

mapfile -t files < <(printf '%s\n' "$INPUT_DIR"/*.tif | sort)
f="${files[$SLURM_ARRAY_TASK_ID]}"
basename=$(basename "$f" .tif)
output="$OUTPUT_DIR/${basename}.ome.tif"

echo "Job $SLURM_ARRAY_TASK_ID processing: $f"

pixi run python ./convert_brainsaw_tiffs.py "$f" "$output" "${INPUT_DIR}/tilePositions.csv"