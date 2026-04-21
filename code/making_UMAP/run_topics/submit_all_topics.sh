#!/bin/bash

# List of topic numbers to try
topics=(5 50 75 100 125 150 175 200)

# Base SLURM script to duplicate and modify
base_script="/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/mallet/run_mallet.sh"

# Directory to store individual job scripts
job_dir="/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/mallet/mallet_topic_jobs"
mkdir -p "$job_dir"

for topic in "${topics[@]}"; do
    # Create a copy of the base script
    job_script="${job_dir}/run_mallet_${topic}.sh"
    cp "$base_script" "$job_script"

    # Insert topic number into the python call using sed
    # Assumes a line like: python /path/to/run_scmallet.py
    sed -i "s|python .*|python /n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/mallet/run_scmallet.py $topic|" "$job_script"

    # Optional: update job name in SLURM header
    sed -i "s/^#SBATCH --job-name=.*/#SBATCH --job-name=mallet_${topic}/" "$job_script"

    # Submit the job
    sbatch "$job_script"
done
