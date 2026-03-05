#!/bin/bash
#
#SBATCH --nodes=32
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=4
#SBATCH --job-name=yambo_gw_kpconv_888
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --time=6:00:00


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
#CPU=$(( OMP_NUM_THREADS * SLURM_NTASKS ))
TASKS=$SLURM_NTASKS
THREADS=$OMP_NUM_THREADS
module load cray-python/3.10.10
VENV=/mnt/lustre/a2fs-work3/work/e89/e89/aromani/py-yambo/bin/
source $VENV/activate
##BSE

#$VENV/python bse_conv_bn0.py  -e -r -t $SLURM_NTASKS -par 
#$VENV/python bse_conv_bn0.py -a
#$VENV/python bse_conv_bn0.py -p -e 
#$VENV/python bse_conv_bn0.py  -b -r -t $SLURM_NTASKS -par 

###GW
#$VENV/python gw_conv_bn.py  -c  -mpi $TASKS -ompi $THREADS
$VENV/python gw_run.py 
