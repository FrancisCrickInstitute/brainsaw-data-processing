#!/bin/bash
#SBATCH --job-name=brainsaw-positions
#SBATCH --ntasks=1
#SBATCH --mem=1G
#SBATCH --partition=ncpu
# Note: --export is set dynamically by the submission script

ml pixi

pixi run --frozen python ./mat_to_csv.py "$INPUT_DIR"