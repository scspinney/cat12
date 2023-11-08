#!/bin/bash

set -eu

module load StdEnv/2020 apptainer/1.1.8

CONTAINER_DIR=/scratch/spinney/containers

singularity build cat12_parallel.sif cat12parallel.singularity.def

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <DATASET_DIR> <SUBJECT_NUM>"
    exit 1
fi

DATASET_DIR="$1"
SUBJECT_NUM="$2"

# Function for running a step with error handling
run_step() {
    step_description="$1"
    script_name="$2"
    
    echo "Running ${step_description}..."
    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "/data/sub-${SUBJECT_NUM}/ses-0{1,2,3}/anat/sub-01_T1w.nii"; then
        echo "${step_description} completed successfully."
    else
        echo "Error: ${step_description} failed. Exiting."
        exit 1
    fi
}

# Step 1: Preprocessing
run_step "Step 1: Preprocessing" "cat_standalone_segment_long.m"

# Step 2: Smoothing of Volume Data
run_step "Step 2: Smoothing of Volume Data" "cat_standalone_smooth.m"

# Step 3: Resample and Smooth Surface Data
run_step "Step 3: Resample and Smooth Surface Data" "step2_script.m"

# Add more steps as needed



/software/CAT12.8.2_MCR/standalone/cat_parallelize.sh -p 8 -l /tmp \
  -c "-m /software/CAT12.8.2_MCR/v93 \
  -b /software/CAT12.8.2_MCR/standalone/cat_standalone_segment_enigma.m" \ 
  /data/enigma-data/raw/sub*.nii