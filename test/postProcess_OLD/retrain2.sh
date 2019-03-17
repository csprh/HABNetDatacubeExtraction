#! /bin/bash

#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --partition gpu
#SBATCH --job-name=gpujob
#SBATCH --mem 2048

module load CUDA
module load libs/tensorflow/1.2

cd $SLURM_SUBMIT_DIR
time python code/retrain.py --image_dir /mnt/storage/scratch/eexna/CV2/set2 --output_graph /mnt/storage/home/eexna/models/volcanoSet2_graphMobile0.001.pb --learning_rate 0.001 --architecture 'mobilenet_1.0_224' --output_labels /mnt/storage/home/eexna/models/volcanoSet2_labelsMobile0.001.txt --summaries_dir /mnt/storage/scratch/eexna/models/retrainSet2_logs4000 --bottleneck_dir /mnt/storage/scratch/eexna/models/bottleneckSet2_Mobile 
