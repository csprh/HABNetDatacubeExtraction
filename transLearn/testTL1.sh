#! /bin/bash

#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --partition gpu
#SBATCH --job-name=gpujob
#SBATCH --mem=16G

module add languages/anaconda3/3.5-4.2.0-tflow-1.7
#module add languages/anaconda2/5.0.1.tensorflow-1.6.0

#which python
#onda list
cd /mnt/storage/home/csprh/code/HAB/extractData/transLearn
python fine-tune.py --val_dir /mnt/storage/home/csprh/scratch/HAB/CNNIms/florida1/train_dir --train_dir /mnt/storage/home/csprh/scratch/HAB/CNNIms/florida1/val_dir