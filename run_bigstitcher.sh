#!/bin/bash
#SBATCH --job-name=brainsaw-stitch
#SBATCH --ntasks=1
#SBATCH --time=1-00:00:00
#SBATCH --mem=256G
#SBATCH --partition=ncpu

ml Java/1.8

mkdir -p "$OUTPUT_DIR"

/nemo/stp/lm/working/barryd/hpc/Fiji.app/ImageJ-linux64 --headless -macro \
    /nemo/stp/lm/working/barryd/hpc/projects/labs/miguel-aliaga/elisa/scripts/define_dataset.ijm \
    "$INPUT_DIR,$OUTPUT_DIR"