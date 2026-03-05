#!/bin/bash
#
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=4
#SBATCH --job-name=yambo_bse_haydoc_forkpointgrid
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --time=00:20:00
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
module purge
module load craype-x86-rome libfabric/1.12.1.2.2.0.0 craype-network-ofi \
            perftools-base/23.09.0 xpmem/0.2.119-1.3_0_gnoinfo \
            cce/16.0.1 craype/2.7.23 cray-dsmml/0.2.2 cray-mpich/8.1.27 \
            cray-libsci/23.09.1.1 PrgEnv-cray/8.4.0 bolt/0.8 epcc-setup-env load-epcc-module

module load PrgEnv-gnu
module load cray-fftw
module load petsc
module load slepc
module load cray-netcdf-hdf5parallel

module load cray-python/3.10.10
yambo = '/work/e89/e89/aromani/source-code/yambo_kevin/bin/yambo'
srun --distribution=block:block --hint=nomultithread /work/e89/e89/aromani/source-code/yambo_kevin/bin/yambo -F yambo_run.in
