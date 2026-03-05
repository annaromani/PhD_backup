
module load cray-python/3.10.10


# Optional but nice: a cache dir
mkdir -p /work/e89/e89/aromani/.cache

export PYTHONPATH=$HOME/.local/lib/python3.10/site-packages:/mnt/lustre/a2fs-work3/work/e89/e89/aromani/source-code/yambopy:$PYTHONPATH

export MPLCONFIGDIR=${SLURM_TMPDIR:-/tmp}/mplconfig
mkdir -p $MPLCONFIGDIR
module load cray-python/3.10.10
VENV=/mnt/lustre/a2fs-work3/work/e89/e89/aromani/py-yambo/bin/
source $VENV/activate
$VENV/python 

