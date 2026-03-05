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
#SBATCH --cpus-per-task=4
#SBATCH --job-name=scf_10
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --time=00:20:0


module load quantum_espresso/7.5

# Run the parallel program
export OMP_NUM_THREADS=4
export SRUN_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK
srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2_nscf_nofixed_magnetization.in  > NiI2_nscf_nofixed_magnetization.out
#srun --hint=nomultithread --distribution=block:block hp.x  -nk 16 < NiI2_hp.in > NiI2_hp_444_U4.out
#-npools==-nk: NB. nodes has to be a multiplier/diviser of npool such that a poll is not devided in more node! nodes/npool=i
#srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2_vcrelax.in  > NiI2_vcrelax.out
#srun --hint=nomultithread --distribution=block:block bands.x < NiI2_bands_pp.in > NiI2_bands_pp.out
#srun --hint=nomultithread --distribution=block:block pw.x -nk 8 < NiI2_bands.in  > NiI2_bands.out &&
#srun --hint=nomultithread --distribution=block:block projwfc.x -nk 8 < NiI2_proj.in  > NiI2_proj.out

#bands.x < NiI2_plotbands.in
