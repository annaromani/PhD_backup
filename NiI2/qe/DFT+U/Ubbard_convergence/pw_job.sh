#!/bin/bash
#
# Parallel script produced by bolt
#        Resource: ARCHER2 (HPE Cray EX (128-core per node))
#    Batch system: Slurm
#
# bolt is written by EPCC (http://www.epcc.ed.ac.uk)
#
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --job-name=scf_10
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=standard
#SBATCH --time=03:20:00


export OMP_PLACES=cores
export OMP_PROC_BIND=close
module load quantum_espresso/7.5

# Run the parallel program
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK
#srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2.scf5.5187.in  > NiI2.scf5.5187.out
#srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2.scf5.49.in > NiI2.scf5.49.out
#srun --hint=nomultithread --distribution=block:block  pw.x -nk 8  < NiI2.scf_6.3990.in   > NiI2.scf_6.3990.out
#srun --hint=nomultithread --distribution=block:block  pw.x -nk 8  < NiI2.bands.in  > NiI2.bands.out
#srun --hint=nomultithread --distribution=block:block bands.x < NiI2.bandsx.in > NiI2.bandsx.out
srun --hint=nomultithread --distribution=block:block hp.x -pd .true. -nk 1 < NiI2_hp.in > NiI2_hp_333_U5.5187.out
#-npools==-nk: NB. nodes has to be a multiplier/diviser of npool such that a poll is not devided in more node! nodes/npool=i
#srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2_vcrelax.in  > NiI2_vcrelax.out
#srun --hint=nomultithread --distribution=block:block bands.x < NiI2_bands_pp.in > NiI2_bands_pp.out
