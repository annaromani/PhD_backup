from yambopy import *
print(YamboIn())
NLDB=YamboNLDB(folder='RT+E_QP', calc='')  #(calc='SAVE file')
pol =NLDB.Polarization[0] #pol= polarization for all laser frequencies in the three Cartesian directions
time=NLDB.IO_TIME_points
Harmonic_Analysis_nm(NLDB,X_order=2) #generate new files with all the requested harmonics o.YamboPy-X_probe_order_1, o.YamboPy-X_probe_order_2 etc...
#see yambopy/nl/harmonic_analysis.py

