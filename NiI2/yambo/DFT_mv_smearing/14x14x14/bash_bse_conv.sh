#!/bin/bash
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --job-name=yambo_14x14x14
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --time=00:20:00


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


# Optional but nice: a cache dir
mkdir -p /work/e89/e89/aromani/.cache

export PYTHONPATH=$HOME/.local/lib/python3.10/site-packages:/mnt/lustre/a2fs-work3/work/e89/e89/aromani/source-code/yambopy:$PYTHONPATH

export MPLCONFIGDIR=${SLURM_TMPDIR:-/tmp}/mplconfig
mkdir -p $MPLCONFIGDIR
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK
CPU=$(( OMP_NUM_THREADS * SLURM_NTASKS ))
TASKS=$SLURM_NTASKS
echo $CPU
THREADS=$OMP_NUM_THREADS
module load cray-python/3.10.10
VENV=/mnt/lustre/a2fs-work3/work/e89/e89/aromani/py-yambo/bin/
source $VENV/activate
##BSE

#$VENV/python bse_conv_bn0.py  -e -r -t $TASKS -par 2>&1
#$VENV/python bse_conv_bn0.py -a -b  &&
#$VENV/python bse_conv_bn0.py -p -b 
#$VENV/python bse_conv_bn0.py  -b -r  -t $SLURM_NTASKS -par 2>&1 
$VENV/python bse_run.py -r -t $SLURM_NTASKS -par 2>&1

####double grid
#$VENV/python bse_run.py -r -dg -t $SLURM_NTASKS 2>&1 
