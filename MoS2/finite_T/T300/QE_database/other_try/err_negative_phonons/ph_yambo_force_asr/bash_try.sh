#!/bin/bash
#SBATCH --nodes=4
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
RUNNER="srun --partition=standard"           # 'srun' or 'mpirun'
PREFIX="MoS2"
INPUT_DIR="./Inputs"
OUTDIR="tmp"            # QE 'outdir' parameter
NP=
DG=true                 # Set to true to run Double Grid steps
PHONON_QGRID=(6 6 1)    # nq1 nq2 nq3
PSEUDO_DIR='pseudo'     ##NB. pseudo dir must be located in the directory where we lauch the code
# Argument parsing for plotting
PLOT_PH=false
for arg in "$@"; do
  if [ "$arg" == "--plot_ph" ]; then PLOT_PH=true; fi
done
RELAX=true
# Binaries
RUN_PATH=$(pwd)
QE_PATH=''
YAMBO_PATH='/work/e89/e89/aromani/source-code/yambo_kevin/bin/'
PW_EXE="${QE_PATH}pw.x"
PH_EXE="${QE_PATH}ph.x"
DYN_EXE="${QE_PATH}dynmat.x"
MATDYN_EXE="${QE_PATH}matdyn.x"
Q2R_EXE="${QE_PATH}q2r.x"
P2Y_EXE="${YAMBO_PATH}p2y"
YAMBO_EXE="${YAMBO_PATH}yambo"
YPP_EXE="${YAMBO_PATH}ypp_ph"
YAMBO_PH_EXE="${YAMBO_PATH}yambo_ph"

$RUNNER $PH_EXE -nk 1 < $PREFIX.ph_yambo_q.in > $PREFIX.ph_yambo_q.out
check_done "$PREFIX.ph_yambo_q.out" "PH_YAMBO"

 --- Optional Plotting Logic ---
if [ "$PLOT_PH" = true ]; then
    echo "--> Plotting Gamma frequencies..."
    cat > stability_check.in << EOF
&input
  fildyn = '$PREFIX.dyn1',
  asr = '2d',
/
EOF
    $DYNMAT_EXE < stability_check.in > stability.out
    grep "freq" stability.out | awk '{print $7}' > freq_list.txt
    # [Insert Python snippet from previous response here]
fi

echo "--> Step 4.5: Checking elph_dir and importing to Yambo"

# Verify elph_dir exists (usually created in the current directory or outdir)
if [ -d "elph_dir" ]; then
    echo "SUCCESS: elph_dir found."

    cd $PREFIX.save
    if [ -d "SAVE" ]; then
        echo "--> Running ypp_ph el-ph import..."
        # Running import using the input file from your Inputs directory
        $YPP_EXE -F $RUN_PATH/$INPUT_DIR/ypp_ph_import.in > ypp_ph_import.out
        grep "Uniform sampling" l_gkkp_gkkp_db
        # Verification: check if elph databases were created
        if ls SAVE/ndb.elph* 1> /dev/null 2>&1; then
            echo "SUCCESS: Electron-phonon databases imported to Yambo SAVE."
        else
            echo "WARNING: ypp_ph ran but ndb.elph files were not found in SAVE/."
        fi
    else
        echo "ERROR: Yambo SAVE directory not found inside $PREFIX.save"
    fi
    cd ..
else
    echo "ERROR: elph_dir was not created by ph.x. Check ph_yambo_q.out for errors."
fi

