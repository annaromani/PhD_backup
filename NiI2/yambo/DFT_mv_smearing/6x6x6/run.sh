
#commands
cd field_dir_modulation_2
srun   --hint=nomultithread --distribution=block:block /work/e89/e89/aromani/source-code/yambo_openmp/bin/yambo -F BLongDir_1_3_0.in -J BLongDir_1_3_0 -C BLongDir_1_3_0 2> BLongDir_1_3_0.log
touch BLongDir_1_3_0/done