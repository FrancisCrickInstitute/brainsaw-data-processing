#!/bin/bash

# Accept optional comma-separated list of file indices as first argument, default to empty string
ARRAY_INDICES=${1:-""}

# Loop over all input directories, generating zero-padded indices from 0001 to 0176
for i in $(seq -f "%04g" 1 2); do
    
    # Construct the full path to the input directory for this iteration
    INPUT_DIR="/nemo/project/proj-miguel-aliaga-brainsaw/data/rawData/CrickSaw_260326_hml_old_young_females_hml-${i}"

    # If specific indices were provided, use them; otherwise calculate the full range from the file count
    if [ -n "$ARRAY_INDICES" ]; then
        # Use the provided indices directly as the array specification
        array_spec="$ARRAY_INDICES"
    else
        # Count the number of tif files in the input directory
        num_files=$(ls "$INPUT_DIR"/*.tif | wc -l)
        # Set the array range from 0 to the number of files minus 1 (zero-indexed)
        array_spec="0-$((num_files - 1))"
    fi

    # Submit the conversion job array to SLURM, passing the input directory as an environment variable
    sbatch --array="$array_spec" \
           --export=INPUT_DIR="$INPUT_DIR" \
           ome_convert.sh
done