#! /bin/bash

#SBATCH --job-name=test_job
#SBATCH --partition=test
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1


module load CUDA
module load apps/matlab/2017a

cd $SLURM_SUBMIT_DIR
echo $SLURM_SUBMIT_DIR
cd /mnt/storage/home/csprh/code/HAB/genHDFData
matlab -nodisplay -nosplash -r pngGenFromH5v2   

