#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=4
#SBATCH --job-name=phonon
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --time=00:20:0

module purge
module load craype-x86-rome \
            libfabric/1.12.1.2.2.0.0 \
            craype-network-ofi \
            perftools-base/23.09.0 \
            xpmem/0.2.119-1.3_0_gnoinfo \
            cce/16.0.1 \
            craype/2.7.23 \
            cray-dsmml/0.2.2 \
            cray-mpich/8.1.27 \
            cray-libsci/23.09.1.1 \
            PrgEnv-cray/8.4.0 \
            bolt/0.8 \
            epcc-setup-env \
            load-epcc-module
module load quantum_espresso/7.3.1
srun pw.x -nk 8 < ../Inputs/MoS2.relax.in > MoS2.relax.out
