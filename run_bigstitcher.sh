#!/bin/bash
#SBATCH --job-name=brainsaw-stitch
#SBATCH --ntasks=1
#SBATCH --time=1-00:00:00
#SBATCH --mem=16G
#SBATCH --partition=ncpu

ml Java/1.8

mkdir -p "$OUTPUT_DIR"

timeout 5m "$FIJI_PATH" --headless -macro ./Run_BigStitcher.ijm "$INPUT_DIR,$OUTPUT_DIR"

exit 0
