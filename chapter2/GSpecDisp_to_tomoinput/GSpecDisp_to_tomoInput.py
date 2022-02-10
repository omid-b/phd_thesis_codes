#!/usr/bin/env python3

# This script generates the input dispersion data format from
# the outputs of the GSpecDisp program to input to the
# Sergei Lebedev's SW Tomography code.

# Note that input sac and mat file names should be in "sta1_sta2_chn.sac" and
# "sta1_sta2_chn.mat" format.

# Errors are assigned based on the differences from the mean of the SNR values:
#      'error adjustment' = -1*SNR_zscore*'error_factor'
#      for SNR>mean(SNRs), 'error adjustment' will be negative
#      error = error0 + 'error adjustment'
#      I recommend a small positive number for 'error_factor';
#      minumum error in <errors> works!

# CODED BY: omid.bagherpur@gmail.com
# UPDATE: March 18, 2021
#=====Adjustable parameters====#
chn_prename = "BH"  # seismic channels prename; could be empty string too!

# script will find singal/noise window based on a range of velocities
signal_velocities = [2.0, 4.5]

min_dist_threshold = 0
min_snr_threshold = 0
error_factor = 0.002
#==============================#

about = 'This script generates the input dispersion data format \
from the outputs of the GSpecDisp program to input to the \
Sergei Lebedev\'s SW Tomography code'

usage = '''
USAGE:
 python3 GSpecDisp_to_tomoInput.py <sac_dir> <mat_dir> <errors> <outp_dir>

Notes:
 1) <sac_dir>: path to the the EGF sacfiles 
    (inputs of the GSpecDisp program; 
    "sta1_sta2_chn.sac" files)

 2) <mat_dir>: path to the inter-station dispersion 
    measurements directory (outputs of the GSpecDisp program; 
    "sta1_sta2_chn.mat" files)

 3) <errors>: a text file with two columns (1) period (2) error

 4) <outp_dir>: path to the output directory (results of this script;
    will be generated if does not exist).

'''

import os
import sys
os.system('clear')
print(f'{about}\n')

if len(sys.argv) != 5:
    print(f"Error USAGE!\n\n{usage}")
    exit()
else:
    sacfilesDir = os.path.abspath(sys.argv[1])
    matfilesDir = os.path.abspath(sys.argv[2])
    errFile = os.path.abspath(sys.argv[3])
    outputDir = os.path.abspath(sys.argv[4])

if not os.path.isdir(sacfilesDir):
    print(f"\nError! Could not find <sac_dir>!\n{usage}\n")
    exit()

if not os.path.isdir(matfilesDir):
    print(f"\nError! Could not find <mat_dir>!\n{usage}\n")
    exit()

if not os.path.isfile(errFile):
    print(f"\nError! Could not find <errors>!\n{usage}\n")
    exit()
else:
    phvelErr0 = {}
    fn = open(errFile,'r')
    for line in fn:
        prd = int(float(line.split()[0]))
        err = float(line.split()[1])
        phvelErr0[f"{prd}"] = err

try:
    import obspy
    import numpy as np
    from glob import glob
    from scipy.io import loadmat
except ImportError as e:
    print(f"\n{e}\n")
    exit()

sacfiles = glob(f"{sacfilesDir}/*_*_*.sac")
matfiles = glob(f"{matfilesDir}/*_*_*.mat")

if len(sacfiles) == 0:
    print("Error! Could not find any '*_*_*.sac' file in the given directory!\n")
    exit()

if len(matfiles) == 0:
    print("Error! Could not find any '*_*_*.mat' file in the given directory!\n")
    exit()

#-----FUNCTIONS-----#
######Classes and Functions######
class EGF:
    def __init__(self, sacfile):
        self.sacfile = sacfile
        st = obspy.read(sacfile)
        self.trace = st[0]

    def sta(self):
        sta1 = os.path.basename(sacfiles[i]).split('_')[0]
        sta2 = os.path.basename(sacfiles[i]).split('_')[1]
        return sta1, sta2

    def key(self):
        sta1, sta2 = self.sta()
        return f"{sta1}_{sta2}"

    def chn(self):
        chn1 = f"{chn_prename}{self.trace.stats.sac.kcmpnm[0]}"
        chn2 = f"{chn_prename}{self.trace.stats.sac.kcmpnm[1]}"
        return chn1, chn2

    def lat(self):
        evla = float(self.trace.stats.sac.evla)
        stla = float(self.trace.stats.sac.stla)
        return evla, stla

    def lon(self):
        evlo = float(self.trace.stats.sac.evlo)
        stlo = float(self.trace.stats.sac.stlo)
        return evlo, stlo

    def dist(self):
        return float(self.trace.stats.sac.dist)

    def data_sym(self):
        data = self.trace.data.tolist()
        zindx = int(len(data)/2)
        acausal = np.array(data[0:zindx+1][::-1])
        causal = np.array(data[zindx::])
        data_sym = (acausal + causal) / 2
        return data_sym.tolist()

    def times_sym(self):
        e = int(self.trace.stats.sac.e)
        delta = float(self.trace.stats.sac.delta)
        times = np.arange(0,e+delta,delta).tolist()
        return times

    def window_times(self):
        data_sym = self.data_sym()
        times_sym = self.times_sym()
        imax = np.where(np.abs(data_sym) == np.amax(np.abs(data_sym)))[0][0]
        tmax = times_sym[imax]
        t1 = self.dist()/signal_velocities[1]
        t2 = self.dist()/signal_velocities[0]
        dt = t2 - t1
        if tmax > t1 and tmax < t2:
            t1 = tmax - (dt / 2)
            t2 = tmax + (dt / 2)
        t3 = t2 + dt
        t4 = t3 + dt
        return t1, t2, t3, t4

    def snr_sym(self):
        signal = []
        noise = []
        data_sym = self.data_sym()
        times_sym = self.times_sym()
        window_times = self.window_times()
        i = -1
        for t in times_sym:
            i += 1
            if t >= window_times[0] and t <= window_times[1]:
                signal.append(data_sym[i])
            if t >= window_times[2] and t <= window_times[3]:
                noise.append(data_sym[i])
        srms = np.sqrt(np.nanmean(np.square(signal)))
        nrms = np.sqrt(np.nanmean(np.square(noise)))
        snr = 20*np.log10(srms/nrms)
        return float(snr)

#-------------------#

print(f"\nCollecting datasets information ...\n")

# keys in the following dictionaries are in "sta1_sta2" format
pair_sta = {}  # station names: [sta1, sta2]; type=list; read from file name!
pair_chn = {}  # station channels: [chn1, chn2]; type=list;
pair_lat = {}  # station latitudes: [lat1, lat2]; type=list;
pair_lon = {}  # station longitudes: [lon1, lon2]; type=list;
pair_dist = {} # inter-station distance: type=float
pair_snr = {}  # EGFs snr values; script will first symmetrize the signal
pair_period = {} # dispersion data periods: type=list
pair_phvel = {} # dispersion data phase velocities: type=list

# read through the sac headers
for i in range(len(sacfiles)):
    egf = EGF(sacfiles[i])
    key = egf.key()
    pair_sta[key] = egf.sta()
    pair_lat[key] = egf.lat()
    pair_lon[key] = egf.lon()
    pair_chn[key] = egf.chn()
    pair_dist[key] = egf.dist()
    pair_snr[key] = egf.snr_sym()

if not os.path.isdir(outputDir):
    os.mkdir(outputDir)
    
prd_uniq = [] # list of unique periods
snrs = [] # list of snr values; used for for statistics

# read through the mat files
selectedMatfiles = []
for i in range(len(matfiles)):
    sta1 = os.path.basename(matfiles[i]).split('_')[0]
    sta2 = os.path.basename(matfiles[i]).split('_')[1]
    key = f"{sta1}_{sta2}"
    data = np.array(loadmat(matfiles[i])['Intdisp'])
    data = data.reshape(1,len(data)*2)[0]
    pair_period[key] = data[0::2].tolist()
    pair_phvel[key] = data[1::2].tolist()

    if (pair_snr[key] >= min_snr_threshold) and (pair_dist[key] >= min_dist_threshold):
        selectedMatfiles.append(matfiles[i])

    snrs.append(pair_snr[key])
    for period in pair_period[key]:
        prd = "%.0f" %(period)
        if int(prd) not in prd_uniq:
            prd_uniq.append(int(prd))


snr0 = np.mean(snrs)
prd_uniq = np.array(sorted(prd_uniq), dtype=int)

#check if errors at all periods are given
for prd in prd_uniq:
    if prd not in np.array(list(phvelErr0.keys()), dtype=int):
        print(f'Error! Could not find reference error at {prd} second!\nCheck <errors>!\n')
        exit()

# Print info in terminal
info = f"  #Periods: {len(prd_uniq)}\n  Period range: {np.min(prd_uniq)}-{np.max(prd_uniq)}\n  Range of given average errors: {min(phvelErr0.values())}-{max(phvelErr0.values())}\n  Signal velocity range (km/s): {signal_velocities[0]}-{signal_velocities[1]}\n  Calculated SNR values (min, average, max, std): %.2f, %.2f, %.2f, %.2f\n  Dataset inter-station distance range (km): %.2f-%.2f\n\n  #Outputs: {len(selectedMatfiles)} of {len(matfiles)}, %.0f%s\n  Min distance threshold (km): %.2f\n  Min SNR threshold: %.2f\n  Error factor: {error_factor}\n\n" %(np.min(snrs), snr0, np.max(snrs), np.std(snrs), min(pair_dist.values()), max(pair_dist.values()), (len(selectedMatfiles)/len(matfiles))*100,'%',min_dist_threshold, min_snr_threshold)

print(info)

uin = input("Do you want to continue (y/n)? ").lower()

if (uin == 'y'):
    print(f"\nGenerating outputs ...\n")
else:
    print("\nExit program!\n")
    exit()


output_error = {}
for i in range(len(prd_uniq)):
    output_error[f'{prd_uniq[i]}'] = []

warning = 0
for mat in selectedMatfiles:
    key = '_'.join(os.path.basename(mat).split('_')[0:2])
    outfile_name = f"{key}_{pair_chn[key][0][-1]}{pair_chn[key][1][-1]}.disp"
    outfile = open(os.path.join(outputDir, outfile_name), 'w')
    outfile.write(f"{pair_sta[key][0]} {pair_sta[key][1]}\n")
    outfile.write(f"{pair_chn[key][0]} {pair_chn[key][1]}\n")
    outfile.write(f"%.4f %.4f %.4f %.4f\n" %(float(pair_lat[key][0]), float(pair_lon[key][0]), float(pair_lat[key][1]), float(pair_lon[key][1])))
    for i in range(len(pair_period[key])):
        prd = f"%.0f" %(pair_period[key][i])
        snr = pair_snr[key]
        err0 = phvelErr0[prd]
        snr_zscore = (snr-snr0)/np.std(snrs)
        err_adj = -1*snr_zscore*error_factor
        err = err0+err_adj
        output_error[prd].append(err)
        if (err < 0):
            warning = 1

        outfile.write(f"%.2f %.4f %.4f\n" %(pair_period[key][i], pair_phvel[key][i], err))
    outfile.close()

readme = open(os.path.join(outputDir,'README'), 'w')

header = "Period  #Measurements  minError  maxError  avgError  stdError"
print(header)
readme.write(f"This is the report of script 'GSpecDisp_to_tomoInput.py'.\n\nsacfiles dir:{sacfilesDir}\nmatfiles dir: {matfilesDir}\n\n{info}\n\n{header}\n\n")
for prd in output_error.keys():
    info = "%6s %14d %9.4f %9.4f %9.4f %9.4f" %(prd, len(output_error[prd]), np.min(output_error[prd]), np.max(output_error[prd]), np.mean(output_error[prd]), np.std(output_error[prd]))
    print(info)
    readme.write(f'{info}\n')

print('\nDone!\n\n')

minErrAdj = 9999
maxErrAdj = -9999
readme.write(f'\n\nDISPERSION    SNR   Error_Adjustment\n\n')
for mat in selectedMatfiles:
    key = '_'.join(os.path.basename(mat).split('_')[0:2])
    errAdj = -1*((pair_snr[key]-snr0)/np.std(snrs))*error_factor
    if errAdj > maxErrAdj:
        maxErrAdj = errAdj

    if errAdj < minErrAdj:
        minErrAdj = errAdj
    readme.write('%10s %6.2f %18.8f\n' %(key, pair_snr[key], errAdj))

readme.write(f'\n\nmin error adjustment: {minErrAdj}\nmax error adjustment: {maxErrAdj}.\n\n')
readme.close()

if warning == 1:
    print('\nWARNING! some errors are negative; set a smaller value for "error_factor"!\n')
