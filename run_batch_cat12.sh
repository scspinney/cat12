#!/bin/bash

# Specify the path to your BIDS dataset directory
DATASET_DIR=/home/spinney/project/data/neuroventure/bids

# Specify the path to the container's working directory
CONTAINER_WORK_DIR=$SCRATCH/cat12tmp/CAT12.8.2

# Check if a subject array is provided as a command line argument
if [ "$#" -gt 0 ]; then
    # Use provided subject array
    subject_numbers=("${@}")
else
    # Extract subject numbers from the directory tree using find
    subject_numbers=($(find "$DATASET_DIR" -maxdepth 2 -type d -name "sub-*" | cut -d'-' -f2))
fi

# Extract subject numbers from the directory tree
#subject_numbers=($(find "$DATASET_DIR" -maxdepth 2 -type d -name "sub-*" | cut -d'-' -f2))
#subject_numbers=(147)

# Check if any subject numbers were found
if [ ${#subject_numbers[@]} -eq 0 ]; then
    echo "No subject directories found in the dataset."
    exit 1
fi


# Submit the array job and capture the job ID
array_job_id1=$(sbatch --array=0-`expr ${#subject_numbers[@]} - 1`%100 \
       --mem=65G \
       --cpus-per-task=8 \
       --time=8:00:00 \
       --output="${SCRATCH}/neuroventure/raw/tmp/output/cat12_%A_%a.out" \
       --error="${SCRATCH}/neuroventure/raw/tmp/error/cat12_%A_%a.err" \
       ${PROJECT}/neuroimaging-preprocessing/src/models/cat12/run_cat12.sh ${DATASET_DIR} ${subject_numbers[@]})

job_number=$(echo $array_job_id1 | awk '{print $NF}')

# # Submit another job with a dependency on the array job
array_job_id2=$(sbatch --dependency=afterok:${job_number} \
       --mem=8G \
       --cpus-per-task=4 \
       --time=2:00:00 \
       --output="${SCRATCH}/neuroventure/raw/tmp/output/combinecat12.out" \
       --error="${SCRATCH}/neuroventure/raw/tmp/error/combinecat12.err" \
       ${PROJECT}/neuroimaging-preprocessing/src/models/cat12/run_combine_reports.sh ${CONTAINER_WORK_DIR})

