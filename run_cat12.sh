#!/bin/bash

set -eu

module load StdEnv/2020 apptainer/1.1.8

CONTAINER_DIR=$PROJECT/containers

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

    # Collect all T1w MRI file paths into an array (RUN 1)
    file_paths=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-01_T1w.nii.gz"))

    # Remap to location in container
    file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    if [ ${#file_paths[@]} -gt 1 ]; then
        script_name="cat_standalone_segment_long.m"
    else
        script_name="cat_standalone_segment_enigma.m"
    fi

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    # Run the command with all file paths
    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"; then
        log "All T1w files completed successfully."
    else
        log "Error: Processing all T1w files failed. Exiting."
        exit 1
    fi

    # Check if there are T1w scans for run-02
    script_name="cat_standalone_segment_enigma.m"
    file_paths_run2=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-02_T1w.nii.gz"))
    file_paths_run2=("${file_paths_run2[@]//\\/}")
    file_paths_run2=("${file_paths_run2[@]/$CONTAINER_DATA_DIR//data}")    

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths_run2[@]}"


    if [ ${#file_paths_run2[@]} -gt 0 ]; then
        log "File Paths (Run 2): ${file_paths_run2[@]}"

        # Run the command with all file paths (RUN 2)
        if singularity run --cleanenv --contain \
            -B "${CONTAINER_DATA_DIR}:/data" \
            -B "$HOME/.matlab" \
            "${CONTAINER_DIR}/cat12-latest.sif" \
            -b "/opt/spm/standalone/${script_name}" "${file_paths_run2[@]}"; then
            log "All T1w files (Run 2) completed successfully."
        fi

    fi

    # Check if there are T1w scans for run-03
    file_paths_run3=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-03_T1w.nii.gz"))
    file_paths_run3=("${file_paths_run3[@]//\\/}")
    file_paths_run3=("${file_paths_run3[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths_run3[@]}"

    if [ ${#file_paths_run3[@]} -gt 0 ]; then
        log "File Paths (Run 3): ${file_paths_run3[@]}"

        # Run the command with all file paths (RUN 3)
        if singularity run --cleanenv --contain \
            -B "${CONTAINER_DATA_DIR}:/data" \
            -B "$HOME/.matlab" \
            "${CONTAINER_DIR}/cat12-latest.sif" \
            -b "/opt/spm/standalone/${script_name}" "${file_paths_run3[@]}"; then
            log "All T1w files (Run 3) completed successfully."
        fi

    fi

    # Check if there are T1w scans for other runs (run-XX)
    other_runs=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-??_T1w.nii.gz" | grep -P 'run-(?!0[1-3])\d+'))
    other_runs=("${other_runs[@]//\\/}")
    other_runs=("${other_runs[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${other_runs[@]}"

    if [ ${#other_runs[@]} -gt 0 ]; then
        log "File Paths (Other Runs): ${other_runs[@]}"
    fi
}



run_smooth_volume_long() {
    step_description="Step 2: Smoothing of Volume Data"
    script_name="cat_standalone_smooth.m"
    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    file_paths=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    #file_paths=($(find "${CONTAINER_DATA_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"
    
    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
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
    #file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "lh.thickness.rsub-${SUBJECT_NUM}_ses-??_T1w"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
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
    #file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    # for both gm and wm:     file_paths=($(find "${CONTAINER_DATA_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"  -a1 "'/data/sub-${SUBJECT_NUM}/Quality_measures_volumes.csv'" -a2 "1"; then
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
    # file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "s12.mesh.thickness.resampled_32k.rsub-${SUBJECT_NUM}_ses-??_*"))
    # Remap to location in container
    # file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All surface thickness resampling and smoothing files completed successfully."
    else
        log "Error: Processing all thickness files failed. Exiting."
        exit 1
    fi
}

run_get_weighted_overall_image_quality_long() {
    step_description="Step 6: Estimate and Save Weighted Overall Image Quality"
    script_name="cat_standalone_get_IQR.m"

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "cat_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/IQR.txt'"; then
        log "Overall image quality checks  completed successfully."
    else
        log "Error: overall image quality checks failed. Exiting."
        exit 1
    fi
}

run_estimate_total_intracranial_volume_long() {
    step_description="Step 7: Estimate Total Intra-cranial Volume (TIV)"
    script_name="cat_standalone_get_TIV.m"

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "cat_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/TIV.txt'" -a2 "1" -a3 "2".; then
        log "TIV estimation completed successfully."
    else
        log "Error: TIV estimation failed. Exiting."
        exit 1
    fi
}

run_estimate_mean_volumes_surface_values_roi_long() {
    step_description="Step 8: Estimate mean volumes and mean surface values inside ROI"
    script_name="cat_standalone_get_ROI_values.m"

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "catROI_rsub-${SUBJECT_NUM}_ses-??_T1w.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/ROI'"; then
        log "mean volume and surface estimation inside ROI estimation completed successfully."
    else
        log "Error: mean volume and surface estimation inside ROI failed. Exiting."
        exit 1
    fi
}

## Cross sectional enigma segmentation

run_segment() {
    step_description="Step 1: Cross-sectional segmentation"
    script_name="cat_standalone_segment_enigma.m"
    
    # Collect all T1w MRI file paths into an array (RUN 1)
    file_paths=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-??_T1w.nii.gz"))

    # Remap to location in container
    file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    # Run the command with all file paths
    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"; then
        log "All T1w files completed successfully."
    else
        log "Error: Processing all T1w files failed. Exiting."
        exit 1
    fi
}


run_smooth_volume() {
    step_description="Step 2: Smoothing of Volume Data"
    script_name="cat_standalone_smooth.m"
    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    file_paths=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1sub-${SUBJECT_NUM}_ses-??_*T1w.nii"))

    # This version grabs both gm and wm
    #file_paths=($(find "${CONTAINER_DATA_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"
    
    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All gm and wm smoothing files completed successfully."
    else
        log "Error: Processing all gm and wm smoothing files failed. Exiting."
        exit 1
    fi
}

run_resample_smooth_surface() {
    step_description="Step 3: Resample and Smooth Surface Data"
    script_name="cat_standalone_resample.m"

    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    #file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "lh.thickness.sub-${SUBJECT_NUM}_ses-??_*T1w"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    # Run the command with all file paths
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "[6 6 6]" -a2 "'s6'"; then
        log "All surface thickness resampling and smoothing files completed successfully."
    else
        log "Error: Processing all thickness files failed. Exiting."
        exit 1
    fi
}

run_get_quality_volume() {
    step_description="Step 4: Estimate and Save Quality Measures for Volume Data"
    script_name="cat_standalone_get_quality.m"
    
    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    #file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    # for both gm and wm:     file_paths=($(find "${CONTAINER_DATA_DIR}" -type f \( -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii" -o -name "mwp2rsub-${SUBJECT_NUM}_ses-??_T1w.nii" \)))
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "mwp1sub-${SUBJECT_NUM}_ses-??_*T1w.nii"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}"  -a1 "'/data/sub-${SUBJECT_NUM}/Quality_measures_volumes.csv'" -a2 "1"; then
        log "All gm and wm estimation of quality files completed successfully."
    else
        log "Error: Processing of estimation of quality failed. Exiting."
        exit 1
    fi
}

run_get_quality_surface() {
    step_description="Step 5: Estimate and Save Quality Measures for Surface Data"
    script_name="cat_standalone_get_quality.m"

    # Collect all grey matter (gm) file paths into an array
    # Note: this is the prefix if you used the large changes "mwmwp1r" 
    # file_paths_gm=($(find "$CONTAINER_DATA_DIR" -type f -name "mwp1rsub-${SUBJECT_NUM}_ses-??_T1w.nii"))

    # This version grabs both gm and wm
    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "s12.mesh.thickness.resampled_32k.sub-${SUBJECT_NUM}_ses-??_*"))
    # Remap to location in container
    # file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
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

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "cat_sub-${SUBJECT_NUM}_ses-??_*T1w*.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")
    
    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/IQR.txt'"; then
        log "Overall image quality checks  completed successfully."
    else
        log "Error: overall image quality checks failed. Exiting."
        exit 1
    fi
}

run_estimate_total_intracranial_volume() {
    step_description="Step 7: Estimate Total Intra-cranial Volume (TIV)"
    script_name="cat_standalone_get_TIV.m"

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "cat_sub-${SUBJECT_NUM}_ses-??_*T1w*.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/TIV.txt'" -a2 "1" -a3 "2".; then
        log "TIV estimation completed successfully."
    else
        log "Error: TIV estimation failed. Exiting."
        exit 1
    fi
}

run_estimate_mean_volumes_surface_values_roi() {
    step_description="Step 8: Estimate mean volumes and mean surface values inside ROI"
    script_name="cat_standalone_get_ROI_values.m"

    file_paths=($(find "${CONTAINER_DATA_DIR}" -type f -name "catROI_sub-${SUBJECT_NUM}_ses-??_*T1w*.xml"))
    # Remap to location in container
    #file_paths=("${file_paths[@]//\\/}")
    file_paths=("${file_paths[@]/$CONTAINER_DATA_DIR//data}")

    log "Running: $step_description"
    log "Script: $script_name"
    log "File Paths: ${file_paths[@]}"

    if singularity run --cleanenv --contain \
      -B "${CONTAINER_DATA_DIR}:/data" \
      -B "$HOME/.matlab" \
      "${CONTAINER_DIR}/cat12-latest.sif" \
      -b "/opt/spm/standalone/${script_name}" "${file_paths[@]}" -a1 "'/data/sub-${SUBJECT_NUM}/ROI'"; then
        log "mean volume and surface estimation inside ROI estimation completed successfully."
    else
        log "Error: mean volume and surface estimation inside ROI failed. Exiting."
        exit 1
    fi
}

# Step 0: Copy the data to slurm tmp dir
CONTAINER_DATA_DIR=$SCRATCH/cat12tmp
mkdir -p ${CONTAINER_DATA_DIR}
rsync -rhv --info=progress2 ${DATASET_DIR}/sub-${SUBJECT_NUM} ${CONTAINER_DATA_DIR}/
use_long=true;
file_paths=($(find "$CONTAINER_DATA_DIR" -type f -name "sub-${SUBJECT_NUM}_ses-??_run-0*_T1w.nii.gz"))

# Rename 
#scontrol update job=$SLURM_ARRAY_JOB_ID JobName="cat12_sub-${SUBJECT_NUM}"
scontrol update job=${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID} JobName="cat12_sub-${SUBJECT_NUM}"


if [ ${#file_paths[@]} -gt 1 ]; then
    use_long=false;
else
    use_long=false;
fi

if $use_long; then
    #touch ${CONTAINER_DATA_DIR}/test_file_long.txt
    # Step 1: Preprocessing
    run_segment_long

    #Step 2: Smoothing of Volume Data
    run_smooth_volume_long

    #Step 3: Resample and Smooth Surface Data
    run_resample_smooth_surface_long 

    # Step 4: Estimate and Save Quality Measures for Volume Data
    run_get_quality_volume_long

    # Step 5: Estimate and Save Quality Measures for Surface Data
    run_get_quality_surface_long

    #Step 6: Estimate and Save Weighted Overall Image Quality
    run_get_weighted_overall_image_quality_long

    #Step 7: Estimate Total Intra-cranial Volume (TIV)
    run_estimate_total_intracranial_volume_long

    #Step 8: Estimate mean volumes and mean surface values inside ROI
    run_estimate_mean_volumes_surface_values_roi_long

else
    #touch ${CONTAINER_DATA_DIR}/test_file_cross.txt
    # Step 1: Preprocessing
    run_segment
    
    #Step 2: Smoothing of Volume Data
    run_smooth_volume

    # Step 3: Resample and Smooth Surface Data
    run_resample_smooth_surface 

    # # Step 4: Estimate and Save Quality Measures for Volume Data
    run_get_quality_volume

    # # # Step 5: Estimate and Save Quality Measures for Surface Data
    run_get_quality_surface

    # # Step 6: Estimate and Save Weighted Overall Image Quality
    run_get_weighted_overall_image_quality

    # # Step 7: Estimate Total Intra-cranial Volume (TIV)
    run_estimate_total_intracranial_volume

    # # Step 8: Estimate mean volumes and mean surface values inside ROI
    run_estimate_mean_volumes_surface_values_roi

fi
