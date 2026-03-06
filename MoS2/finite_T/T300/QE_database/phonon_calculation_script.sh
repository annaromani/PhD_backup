#!/bin/bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=16
#SBATCH --cpus-per-task=1
#SBATCH --job-name=phonon
#SBATCH --account=e89-qub_p
#SBATCH --partition=standard
#SBATCH --qos=short
#SBATCH --time=00:20:0

#module purge
#module load craype-x86-rome \
#            libfabric/1.12.1.2.2.0.0 \
#            craype-network-ofi \
#            perftools-base/23.09.0 \
#            xpmem/0.2.119-1.3_0_gnoinfo \
#            cce/16.0.1 \
#            craype/2.7.23 \
#            cray-dsmml/0.2.2 \
#            cray-mpich/8.1.27 \
#            cray-libsci/23.09.1.1 \
#            PrgEnv-cray/8.4.0 \
#            bolt/0.8 \
#            epcc-setup-env \
#            load-epcc-module
module load quantum_espresso/7.5

# Run the parallel program
export OMP_NUM_THREADS=1 #$SLURM_CPUS_PER_TASK
export SRUN_CPUS_PER_TASK=1 #$SLURM_CPUS_PER_TASK
# ==============================================================================
RUNNER="srun --partition=standard"           # 'srun' or 'mpirun'
PREFIX="MoS2"
INPUT_DIR="./Inputs"
OUTDIR="tmp"            # QE 'outdir' parameter
NP=
DG=true                 # Set to true to run Double Grid steps
PHONON_QGRID=(6 6 1)    # nq1 nq2 nq3
PSEUDO_DIR='pseudo'	##NB. pseudo dir must be located in the directory where we lauch the code
# Argument parsing for plotting
PLOT_PH=true
#input_GP=output of matdin used to plot
INPUT_GP="MoS2.freq.gp"
#fig file
SVG_OUT="ars_matdyn_check.svg"

RELAX=true
DOUBLE_RELAX=true
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

# ==============================================================================
# PRE-FLIGHT INPUT CHECK
# ==============================================================================
echo "--> Checking for required input files in $INPUT_DIR..."

# List every file the script will eventually look for
REQUIRED_FILES=(
    "$PREFIX.scf.in" 
    "$PREFIX.nscf.in" 
    "ypp_find_q.in" 
    "$PREFIX.ph_dvscf.in" 
    "$PREFIX.ph_yambo.in" 
    "ypp_ph_import.in"
    "q2r.in" 
    "matdyn.in" 
    "ypp_dg.in"
)

MISSING_COUNT=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$INPUT_DIR/$file" ]; then
        echo "❌ MISSING: $INPUT_DIR/$file"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done

if [ $MISSING_COUNT -gt 0 ]; then
    echo "--------------------------------------------------"
    echo "Error: $MISSING_COUNT file(s) are missing from $INPUT_DIR."
    echo "Please provide them before running the script."
    exit 1
else
    echo "✅ All required inputs found. Proceeding..."
fi


echo "--> Checking for pseudo dir in the current location"
if [ ! -d "$PSEUDO_DIR" ]; then
	echo "❌ MISSING: $PSEUDO_DIR"
fi



# ==============================================================================
# UTILS
# ==============================================================================
check_done() {
    if ! grep -q "DONE" "$1" && ! grep -q "End of" "$1" && ! grep -q "JOB DONE" "$1"; then
        echo "WARNING: Step $2 might have failed. 'DONE' not found in $1"
    fi
}

# Create base work area
mkdir -p nscf ph_dvscf ph_yambo scf



matdyn_step() {
    
########## to call inside the directory ph_*

    # Create .dyn0 file
    echo "${PHONON_QGRID[0]} ${PHONON_QGRID[1]} ${PHONON_QGRID[2]}" > $PREFIX.dyn0
    
    head -n 1 ../nscf/"Q-points_IBZ.txt" >> $PREFIX.dyn0
    
    # Copy q-coords only (columns 1, 2, 3) from the formatted text file
    tail -n +2 ../nscf/"Q-points_IBZ.txt" | awk '{print $1, $2, $3}' >> $PREFIX.dyn0
    # Run q2r and matdyn
    echo "--> Running q2r.x and matdyn.x..."
    $Q2R_EXE < ../$INPUT_DIR/q2r.in > q2r.out
    $MATDYN_EXE < ../$INPUT_DIR/matdyn.in > matdyn.out
}

# ==============================================================================
# 1. SCF STEP
# ==============================================================================
#if [ "$RELAX" = true ]; then
#    echo "--> Step 0: Running Relaxation..."
#    mkdir -p relax 
#    cd relax
#    $RUNNER $PW_EXE < ../$INPUT_DIR/$PREFIX.relax.in > $PREFIX.relax.out
#    check_done "$PREFIX.relax.out" "RELAX"
#
#    echo "--> Extracting relaxed coordinates..."
#    # Extract lines between ATOMIC_POSITIONS and End final coordinates
#    awk '/Begin final coordinates/,/End final coordinates/ {if ($2 ~ /^-?[0-9]/) print $0}' $PREFIX.relax.out > relaxed_coords.txt 
#    # Updated helper to keep the original header
#    update_coords() {
#        local template=$1
#        local output=$2
#        local coord_data="relaxed_coords.txt"
#    
#        awk -v cfile="$coord_data" '
#            /ATOMIC_POSITIONS/ {
#                print $0                               # Print template header
#                while ((getline < cfile) > 0) print $0  # Insert new atoms
#                skip=1                                 # Start skipping old atoms
#                next
#            }
#            /K_POINTS/ { skip=0 }                      # Stop skipping at K_POINTS
#            !skip { print $0 }                         # Print everything else
#        ' "$template" > "$output"
#    }
# 
#    
#    if [ "$DOUBLE_RELAX" = true ]; then
#	    update_coords "../$INPUT_DIR/$PREFIX.relax.in" "$PREFIX.relax_relax.in"
#	    $RUNNER $PW_EXE < $PREFIX.relax_relax.in > $PREFIX.relax_relax.out
#	    awk '/Begin final coordinates/,/End final coordinates/ {if ($2 ~ /^-?[0-9]/) print $0}' $PREFIX.relax_relax.out > relaxed_coords.txt
#    fi
#
#    echo "--> Generating relaxed SCF and NSCF inputs..."
#    update_coords "../$INPUT_DIR/$PREFIX.scf.in" "../scf/$PREFIX.scf_relaxed.in"
#    update_coords "../$INPUT_DIR/$PREFIX.nscf.in" "../nscf/$PREFIX.nscf_relaxed.in"
#    
#    cd ..
#    
#    echo "--> Running SCF with relaxed coordinates..."
#    cd scf
#    $RUNNER $PW_EXE < $PREFIX.scf_relaxed.in > $PREFIX.scf.out
#    cd ..
#else
#    echo "--> Step 1: Running standard SCF (No Relaxation)..."
#    cd scf
#    $RUNNER $PW_EXE < ../$INPUT_DIR/$PREFIX.scf.in > $PREFIX.scf.out
#    cd ..
#fi
#
## ==============================================================================
## 2. NSCF & YPP STEP (Extracting Q-points)
### ==============================================================================
#echo "--> Running NSCF and YPP..."
#    # Copy SCF database
#cp -r scf/$OUTDIR nscf/
#cd nscf
#
#if [ "$RELAX" = true ]; then
#    # Use the relaxed version we generated in Step 0
#    $RUNNER $PW_EXE < $PREFIX.nscf_relaxed.in > $PREFIX.nscf.out
#else
#    # Use the original version from Inputs
#    $RUNNER $PW_EXE < ../$INPUT_DIR/$PREFIX.nscf.in > $PREFIX.nscf.out
#fi
#check_done "$PREFIX.nscf.out" "NSCF"
#
#    # Yambo Interface
#cd $OUTDIR/$PREFIX.save
#$P2Y_EXE &&
#$YAMBO_PH_EXE -i  &&
#$YAMBO_PH_EXE    &&
#$YPP_EXE -F ../../../$INPUT_DIR/ypp_find_q.in > ypp_find_q.out
#
#   #Advanced Extraction: Flip signs, Keep 4th col, Count lines
##awk '/Q-points \(IBZ\) PW-formatted/ {flag=1; next} /\[/ {flag=0} flag {if($1!="") print -$1, -$2, -$3, $4}' l_bzgrids_Q_grid > tmp_q.txt
#
#awk '/Q-points \(IBZ\) PW-formatted/ {flag=1; next} /\[/ {flag=0} flag {if($1!="") printf "%.9f %.9f %.9f %i\n", -$1, -$2, -$3, $4}' l_bzgrids_Q_grid > tmp_q.txt
#
#NQ_IBZ=$(wc -l < tmp_q.txt)
#echo "$NQ_IBZ" > ../../"Q-points_IBZ.txt"
#cat tmp_q.txt >> ../../"Q-points_IBZ.txt"
#rm tmp_q.txt
#cd ../../..

# ==============================================================================
# 3. PH_DVSCF STEP
# ==============================================================================
echo "--> Running PH_DVSCF..."
cd ph_dvscf
#ln -fs ../scf/$OUTDIR/$PREFIX.save 
#cp ../$INPUT_DIR/$PREFIX.ph_dvscf.in $PREFIX.ph_dvscf_q.in
#cat ../nscf/"Q-points_IBZ.txt" >> $PREFIX.ph_dvscf_q.in

$RUNNER $PH_EXE -nk 1 < $PREFIX.ph_dvscf_q.in > $PREFIX.ph_dvscf_q.out
check_done "$PREFIX.ph_dvscf_q.out" "PH_DVSCF"
	
echo "check phonon energy at all kpoints:"

matdyn_step
module load gnuplot

COLS=$(head -n 1 $INPUT_GP | wc -w)

echo "Plotting $INPUT_GP with $COLS columns..."

gnuplot -p << EOF
    set terminal svg size 800,600 background "white"
    set output '${SVG_OUT}'
    set title "MoS2 Phonon Dispersion"
    set ylabel "Frequency (cm^{-1})"
    set xlabel "Wavevector"
    set grid
    # Plot columns 2 through the end (column 1 is the x-axis)
    plot for [i=2:$COLS] '${INPUT_GP}' u 1:i w l lw 2 notitle

    set terminal x11
    replot
EOF
echo "check ${SVG_OUT} file: phonon frequency must be zero at gamma and non negative"

cd ..

# ==============================================================================
# 4. PH_YAMBO STEP
# ==============================================================================
echo "--> Running PH_YAMBO..."
mkdir -p ph_yambo 
cd ph_yambo
cp ../$INPUT_DIR/$PREFIX.ph_yambo.in $PREFIX.ph_yambo_q.in
cat ../nscf/"Q-points_IBZ.txt" >> $PREFIX.ph_yambo_q.in
cp -r  ../ph_dvscf/_ph0 .
cp ../ph_dvscf/$PREFIX.dyn* .
cp -r ../nscf/$OUTDIR/$PREFIX.save . 
$RUNNER $PH_EXE -nk 1 < $PREFIX.ph_yambo_q.in > $PREFIX.ph_yambo_q.out
check_done "$PREFIX.ph_yambo_q.out" "PH_YAMBO"


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

cd ..

# ==============================================================================
# 5. DOUBLE GRID STEP (IF DG=TRUE)
# ==============================================================================

if [ "$DG" = true ]; then
    echo "--> Starting Double Grid Calculation..."
    cd ph_yambo 
    if  [ ! -f "$INPUT_GP" ]; then    
    	matdyn_step
    fi     

    # Yambo DG Interpolation
    cd $PREFIX.save
    if [ -d "SAVE" ]; then
        echo "--> Running ypp_ph Double Grid..."
        $P2Y_EXE
	$YAMBO_EXE
	$YPP_EXE -F $RUN_PATH/$INPUT_DIR/ypp_dg.in > ypp_dg.out
        
        if [ -f "SAVE/ndb.PH_Double_Grid" ]; then
            echo "SUCCESS: ndb.PH_Double_Grid created."
        else
            echo "ERROR: ndb.PH_Double_Grid NOT found."
        fi
    else
        echo "ERROR: Yambo SAVE directory not found inside $PREFIX.save"
    fi
    cd ../..
fi

echo "Workflow Complete."
