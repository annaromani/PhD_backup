
#commands
export SRUN_CPUS_PER_TASK=$SRUN_CPUS_PER_TASK
export OMP_NUM_THREADS=$OMP_NUM_THREADS
cd bse_run_hydoc_28_38; srun --distribution=block:block --hint=nomultithread  /work/e89/e89/aromani/source-code/yambo_kevin/bin/yambo -F yambo_run.in 2> srun.out