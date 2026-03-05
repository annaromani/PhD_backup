module load cray-python/3.10.10
python3 -m venv /work/e89/e89/aromani/virtual_env/python3.10
source /work/e89/e89/aromani/virtual_env/python3.10/bin/activate

pip install --upgrade pip
pip install numpy matplotlib
pip install -e /work/e89/e89/aromani/source-code/yambopy
