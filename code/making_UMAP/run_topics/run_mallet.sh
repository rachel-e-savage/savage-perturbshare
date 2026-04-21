#!/bin/bash
#SBATCH --job-name=cistopic_run
#SBATCH --partition=sapphire         
#SBATCH --time=24:00:00          
#SBATCH -c 32       
#SBATCH --mem=100G               
#SBATCH --output=/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/cistopic_output.log # Save output log
#SBATCH --error=/n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/cistopic_error.log  # Save error log

# Load the necessary environment
mamba init
mamba activate scmallet  # Activate the scmallet conda environment

# Run the Python script that handles everything
python /n/holylfs06/LABS/buenrostro_lab/Users/rsavage/minimorf/final_terra/cistopic/mallet/run_scmallet.py

# Confirm the model saving
echo "cisTopic modeling completed and models saved successfully."

# Deactivate the environment (optional)
mamba deactivate
