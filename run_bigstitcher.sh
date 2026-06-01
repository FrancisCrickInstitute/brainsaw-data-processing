#!/bin/bash
#SBATCH --job-name=brainsaw-define-dataset
#SBATCH --ntasks=1
#SBATCH --time=1-00:00:00
#SBATCH --mem=256G
#SBATCH --partition=ncpu

ml Java/1.8

#INPUT_DIR="/nemo/stp/lm/working/barryd/hpc/projects/labs/miguel-aliaga/elisa/brainsaw-tiff-converter-outputs/CrickSaw_260326_hml_old_young_females_hml-0003"
OUTPUT_DIR="/nemo/stp/lm/working/barryd/hpc/projects/labs/miguel-aliaga/elisa/brainsaw-bigstitcher-tiff-converter-outputs/CrickSaw_260326_hml_old_young_females_hml-0001-0003-fused"
INPUT_DIR="/nemo/stp/lm/working/barryd/hpc/projects/labs/miguel-aliaga/elisa/brainsaw-bigstitcher-tiff-converter-outputs"


mkdir -p "$OUTPUT_DIR"

/nemo/stp/lm/working/barryd/hpc/Fiji.app/ImageJ-linux64 --headless -macro /nemo/stp/lm/working/barryd/hpc/projects/labs/miguel-aliaga/elisa/scripts/define_dataset.ijm "$INPUT_DIR,$OUTPUT_DIR"
