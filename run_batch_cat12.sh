#!/bin/bash

# Specify the path to your BIDS dataset directory
DATASET_DIR=/home/spinney/project/data/neuroventure/raw/bids
# Specify the account
ACCOUNT="def-patricia"

# Extract subject numbers from the directory tree
subject_numbers=($(find "$DATASET_DIR" -maxdepth 2 -type d -name "sub-*" | cut -d'-' -f2))

# Check if any subject numbers were found
if [ ${#subject_numbers[@]} -eq 0 ]; then
    echo "No subject directories found in the dataset."
    exit 1
fi

subject_numbers=("001")

# Loop through the subject numbers and submit an sbatch job for each subject
# for subject_num in "${subject_numbers[@]}"; do
#     # Define the job name
#     job_name="cat12_${subject_num}"

    # Use sbatch to submit the job
sbatch --array=0-`expr ${#subject_numbers[@]} - 1`%100 \
       --mem=65G \
       --cpus-per-task=8 \
       --time=4:00:00 \
       --output="/home/spinney/scratch/neuroventure/raw/tmp/output/cat12_%A.out" \
       --error="/home/spinney/scratch/neuroventure/raw/tmp/error/cat12_%A.err" \
       /home/spinney/project/spinney/neuroimaging-preprocessing/src/models/run_cat12.sh ${DATASET_DIR} ${subject_num[@]}
# done
