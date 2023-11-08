#!/bin/bash

set -eu

module load StdEnv/2020 apptainer/1.1.8

CONTAINER_DIR=/scratch/spinney/containers

# # Check if the correct number of arguments is provided
# if [ "$#" -ne 2 ]; then
#     log "Usage: $0 <DATASET_DIR> <SUBJECT_NUM>"
#     exit 1
# fi

DATASET_DIR=${1}
#SUBJECT_NUM="$2"
SUBJECT_NUMS=("${@:2}")
SUBJECT_NUM=${SUBJECT_NUMS[${SLURM_ARRAY_TASK_ID}]}

# Logging Function
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}


run_segment_long() {
    step_description="Step 1: Longitindal segmentation"
    script_name="cat_standalone_segment_long.m"

    # Collect all T1w MRI file paths into an array
    file_paths=($(find "$DATASET_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_T1w.nii.gz"))

    # Remap to location in container
    file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    # Run the command with all file paths
    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"; then
        log "All T1w files completed successfully."
    else
        log "Error: Processing all T1w files failed. Exiting."
        exit 1
    fi
}


run_smooth_volume_long() {
    step_description="Step 2: Smoothing of Volume Data"
    script_name="cat_standalone_smooth.m"
    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    file_paths=($(find "$DATASET_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    #file_paths=($(find "${DATASET_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"
    
    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All gm and wm smoothing files completed successfully."
    else
        log "Error: Processing all gm and wm smoothing files failed. Exiting."
        exit 1
    fi
}

run_resample_smooth_surface_long() {
    step_description="Step 3: Resample and Smooth Surface Data"
    script_name="cat_standalone_resample.m"

    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    #file_paths_gm=($(find "$DATASET_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${DATASET_DIR}" -type f -name "lh.thickness.rsub-${SUBJECT_NUM}_ses-??_T1w"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All surface thickness resampling and smoothing files completed successfully."
    else
        log "Error: Processing all thickness files failed. Exiting."
        exit 1
    fi
}

run_get_quality_volume_long() {
    step_description="Step 4: Estimate and Save Quality Measures for Volume Data"
    script_name="cat_standalone_get_quality.m"
    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    #file_paths_gm=($(find "$DATASET_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    # for both gm and wm:     file_paths=($(find "${DATASET_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    file_paths=($(find "${DATASET_DIR}" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"  -a1 "'/data/Quality_measures_volumes.csv'" -a2 "1"; then
        log "All gm and wm estimation of quality files completed successfully."
    else
        log "Error: Processing of estimation of quality failed. Exiting."
        exit 1
    fi
}

run_get_quality_surface_long() {
    step_description="Step 5: Estimate and Save Quality Measures for Surface Data"
    script_name="cat_standalone_get_quality.m"

    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    # file_paths_gm=($(find "$DATASET_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${DATASET_DIR}" -type f -name "s12.mesh.thickness.resampled_32k.rsub-${SUBJECT_NUM}_ses-??_*"))
    # Remap to location in container
    # file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All surface thickness resampling and smoothing files completed successfully."
    else
        log "Error: Processing all thickness files failed. Exiting."
        exit 1
    fi
}

run_get_weighted_overall_image_quality() {
    step_description="Step 6: Estimate and Save Weighted Overall Image Quality"
    script_name="cat_standalone_get_IQR.m"

    file_paths=($(find "${DATASET_DIR}" -type f -name "cat_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'IQR.txt'"; then
        log "Overall image quality checks  completed successfully."
    else
        log "Error: overall image quality checks failed. Exiting."
        exit 1
    fi
}

run_estimate_total_intracranial_volume() {
    step_description="Step 7: Estimate Total Intra-cranial Volume (TIV)"
    script_name="cat_standalone_get_TIV.m"

    file_paths=($(find "${DATASET_DIR}" -type f -name "cat_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'TIV.txt'" -a2 "1" -a3 "0".; then
        log "TIV estimation completed successfully."
    else
        log "Error: TIV estimation failed. Exiting."
        exit 1
    fi
}

run_estimate_mean_volumes_surface_values_roi() {
    step_description="Step 8: Estimate mean volumes and mean surface values inside ROI"
    script_name="cat_standalone_get_ROI_values.m"

    file_paths=($(find "${DATASET_DIR}" -type f -name "catROI_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'ROI'"; then
        log "mean volume and surface estimation inside ROI estimation completed successfully."
    else
        log "Error: mean volume and surface estimation inside ROI failed. Exiting."
        exit 1
    fi
}

run_estimate_mean_volumes_surface_values_roi_all() {
    step_description="Step 8: Estimate mean volumes and mean surface values inside ROI"
    script_name="cat_standalone_get_ROI_values.m"

    #file_paths=($(find "${DATASET_DIR}" -type f -name "catROI_rsub-??_ses-??_T1w.xml"))
    file_paths=($(find "${DATASET_DIR}" -type f -iname "catROI_rsub-*_ses-*_T1w.xml"))

    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$DATASET_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "/home/spinney:/home/spinney" \
      -B "${DATASET_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'ROI'"; then
        log "mean volume and surface estimation inside ROI estimation completed successfully. Moving results..."
        mv -v /home/spinney/ROI*.csv $DATASET_DIR/
    else
        log "Error: mean volume and surface estimation inside ROI failed. Exiting."
        exit 1
    fi
}



# Step 1: Preprocessing
run_segment_long

# Step 2: Smoothing of Volume Data
run_smooth_volume_long

# Step 3: Resample and Smooth Surface Data
run_resample_smooth_surface_long 

# Step 4: Estimate and Save Quality Measures for Volume Data
run_get_quality_volume_long

# Step 5: Estimate and Save Quality Measures for Surface Data
run_get_quality_surface_long

# Step 6: Estimate and Save Weighted Overall Image Quality
run_get_weighted_overall_image_quality

# Step 7: Estimate Total Intra-cranial Volume (TIV)
run_estimate_total_intracranial_volume

# Step 8: Estimate mean volumes and mean surface values inside ROI
run_estimate_mean_volumes_surface_values_roi_all