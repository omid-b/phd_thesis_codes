#!/usr/local/bin/python

about = 'This script carries out seasonality analysis of seismic ambient noise cross-correlograms.\n'

usage = '''
# Usage 1: generate season-stacked cross-correlograms
> python3 ANT_seasonality.py  daily_xcorrs_dir  season_stack_dir  num_months

# Usage 2: group season-stacked cross-correlograms into different backazimuthal groups
          (N, NE, E, SE, S, SW, W, NW) based on the orientations of the interstation pairs
> python3 ANT_seasonality.py  season_stack_dir

# Usage 3: perform the seasonality analysis on the previously processed
          season-stacked cross-correlograms (usage 1 and 2) and store the calculations
          into a pandas pickle file (*.pkl)
> python3 ANT_seasonality.py  season_stack_dir  pickle_filename

# Usage 4: generate the seasonality analysis plots
> python3 ANT_seasonality.py  pickle_file
---------------------------------------------------------------------
# daily_xcorrs_dir: path to the directory that contains cross-correlation 
                  daily record folders with "YYJJJ000000" naming format

# season_stack_dir: The results for season-stacked cross correlograms 
             containing (or will contain) folders with "??-??" naming format 
             where ?? are from 01 (January) to 12 (December)

# num_months: an integer that should be in [1, 2, 3, 4, 6]

# pickle_filename: This script will store the calculation results into this pandas pickle format
             that will be used in USAGE 4 for plotting (note: enter "pickle_filename" without ".pkl")

# pickle_file: this file is generated in the previous step (USAGE 3; pickle_filename.pkl)
             Note: this input should have "pkl" file extension
                
'''

# Note: This script first symmetrizes EGFs before calculation of SNR values (usage 3)

# UPDATE: 21 Jan 2021
# CODED BY: omid.bagherpur@gmail.com
#====Adjustable Parameters=====#
SAC = "/usr/local/sac/bin/sac"  # path to SAC software

xcorr_dir_regex = '(^[0-9]{11})'
sacfile_regex = 'sac$'  # regular expression for sac files

# Usage 2 parameters:
general_directions = True
additional_direction = False # True or False
additional_baz_range = [120, 200]

# Usage 3 parameters:
seism_cut = 1000 # xcorr limits to be stored in the pickle file; also used in usage4
signal_vel = [2, 4.5] # signal window velocity range (km/s); used in SNR calculation
bandpass_prd = [] # a list of two bandpass corner periods (s); empty list for no bandpass
correct_snr = True # True/False; correct snr values for number of stacks in xcorrs

# Usage 4 parameters:
station_analysis = False # plot seasonal changes of a station
# selected_season_index = range(12) # only in region-based analysis
selected_season_index = range(0,12,3) # only in region-based analysis

# plot parameters:
figsize = 10 # a list of two numbers; [xSize, ySize]
figure_dpi = 150 # dpi = dot per inch
seismogram_amp_factor = 0.5 # affects the amplitude of EGFs in the EGF plots
seismogram_line_width = 0.5 # seismogram line width (pixels) in the EGF plots
sns_context = "poster" # seaborn context (paper, notebook, poster, talk); affects annotation size
scatter_plot_errors = False
#==============================#
import os
# os.system('clear')
print(about)

# import required modules
try:
    import sys
    import re
    from obspy import read
    import shutil
    import subprocess
    import numpy as np
    import seaborn as sns
    import pandas as pd
    from glob import glob
    from datetime import datetime
    import matplotlib.pyplot as plt
except ImportError as e:
    print(f'Import Error!\n{e}\n')
    exit()

bp = False
if len(bandpass_prd) == 2:
    if bandpass_prd[0] < bandpass_prd[1]:
        bp = True
        cf1 = 1/bandpass_prd[1]
        cf2 = 1/bandpass_prd[0]
    else:
        print("Error in 'bandpass_prd' parameter; check 'Adjustable Parameters' section\n\n")
        exit()

#----FUNCTIONS----#

def get_seasons(num_months):
    season_months = []
    seasons_names = []
    for i in range(1,13):
        seas = []
        for j in range(num_months):
            if (i+j) < 13:
                seas.append(i+j)
            else:
                seas.append(i+j-12)
        season_months.append(seas)
        seasons_names.append(f'%02d-%02d' %(seas[0], seas[-1]))
    return season_months, seasons_names


def get_month(strDate):
    strDate = strDate[0:5]
    month = datetime.strptime(strDate, '%y%j').date().strftime('%m')
    return int(month)


def stack(stacklist, outsac):
    nStacked = 0
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append("fg line 0 0 delta 1 npts 172801 begin -86400")
    for xcorr in stacklist:
        nStacked += 1
        if nStacked == 1:
            sf = read(xcorr, format='SAC', headonly=True)
            kstnm = str(sf[0].stats.sac.kstnm)
            stla = float(sf[0].stats.sac.stla)
            stlo = float(sf[0].stats.sac.stlo)
            stel = float(sf[0].stats.sac.stel)
            evla = float(sf[0].stats.sac.evla)
            evlo = float(sf[0].stats.sac.evlo)
            evel = float(sf[0].stats.sac.evel)
            kcmpnm = str(sf[0].stats.sac.kcmpnm)
            knetwk = str(sf[0].stats.sac.knetwk)
        shell_cmd.append(f"addf {xcorr}")
    shell_cmd.append(f'w {outsac}')
    shell_cmd.append(f'r {outsac}')
    shell_cmd.append(f"chnhdr kevnm '{int(nStacked)}'")
    shell_cmd.append(f"chnhdr kstnm {kstnm}")
    shell_cmd.append(f"chnhdr stla {stla}")
    shell_cmd.append(f"chnhdr stlo {stlo}")
    shell_cmd.append(f"chnhdr stel {stel}")
    shell_cmd.append(f"chnhdr evla {evla}")
    shell_cmd.append(f"chnhdr evlo {evlo}")
    shell_cmd.append(f"chnhdr evel {evel}")
    shell_cmd.append(f"chnhdr kcmpnm {kcmpnm}")
    shell_cmd.append(f"chnhdr knetwk {knetwk}")
    shell_cmd.append(f'wh')
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)


def sym_sac(inpSac, outSac):
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append(f'r {inpSac}')
    if bp:
        shell_cmd.append(f'bp co {cf1} {cf2} n 3 p 2')
    shell_cmd.append('reverse')
    shell_cmd.append('w rev.tmp')
    shell_cmd.append(f'r {inpSac}')
    if bp:
        shell_cmd.append(f'bp co {cf1} {cf2} n 3 p 2')
    shell_cmd.append('addf rev.tmp')
    shell_cmd.append('div 2')
    shell_cmd.append(f'w {outSac}')
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)
    os.remove('rev.tmp')


def causal_sac(inpSac, outSac):
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append(f'cut 0 e')
    shell_cmd.append(f'r {inpSac}')
    if bp:
        shell_cmd.append(f'bp co {cf1} {cf2} n 3 p 2')

    shell_cmd.append(f'w {outSac}')
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)


def acausal_sac(inpSac, outSac):
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append(f'r {inpSac}')
    if bp:
        shell_cmd.append(f'bp co {cf1} {cf2} n 3 p 2')
    shell_cmd.append('reverse')
    shell_cmd.append('w rev.tmp')
    shell_cmd.append(f'cut 0 e')
    shell_cmd.append(f'r rev.tmp')
    shell_cmd.append(f'w {outSac}')
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)
    os.remove('rev.tmp')


def get_signal_window_times(inpSac):
    st = read(inpSac, format='SAC')
    dist = st[0].stats.sac.dist
    t1 = dist/signal_vel[1]
    t2 = dist/signal_vel[0]
    return [t1, t2]


def get_noise_window_times(inpSac):
    st = read(inpSac, format='SAC')
    dist = st[0].stats.sac.dist
    t0 = dist/signal_vel[1]
    t1 = dist/signal_vel[0]
    t2 = t0+ t1
    return [t1+50, t2+50]


def cut_sac(inpSac, outSac, t1, t2):
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append(f'cut {t1} {t2}')
    shell_cmd.append(f'r {inpSac}')
    if bp:
        shell_cmd.append(f'bp co {cf1} {cf2} n 3 p 2')
    shell_cmd.append(f'w {outSac}')
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)


def get_sac_data(inpSac):
    st = read(inpSac, format='SAC')
    b = st[0].stats.sac.b
    e = st[0].stats.sac.e
    delta = st[0].stats.sac.delta
    amps = st[0].data
    times = np.arange(b, e+delta, delta)
    return amps, times


def calc_snr(signal, noise):
    srms = np.sqrt(np.nanmean(np.square(signal)))
    nrms = np.sqrt(np.nanmean(np.square(noise)))
    snr = 10*np.log10((srms**2)/(nrms**2))
    return snr


def correct_snr_value(snr, nstack, mean_nstack):
    nstack_factor = np.sqrt(mean_nstack)/np.sqrt(nstack)
    corrected_snr = snr*nstack_factor
    return float(corrected_snr)


def get_baz_direction(sacfile):
    st = read(sacfile, headonly=True)
    baz = float(st[0].stats.sac.baz)
    if baz < 22.5 or 337.5 <= baz:
        baz_direction = 'N'
    elif 22.5 <= baz < 67.5:
        baz_direction = 'NE'
    elif 67.5 <= baz < 112.5:
        baz_direction = 'E'
    elif 112.5 <= baz < 157.5:
        baz_direction = 'SE'
    elif 157.5 <= baz < 202.5:
        baz_direction = 'S'
    elif 202.5 <= baz < 247.5:
        baz_direction = 'SW'
    elif 247.5 <= baz < 292.5:
        baz_direction = 'W'
    elif 292.5 <= baz < 337.5:
        baz_direction = 'NW'
    return baz_direction


def is_baz_in_range(sacfile, baz_range):
    is_in_range = False
    reverse_require = False
    st = read(sacfile, headonly=True)
    baz = float(st[0].stats.sac.baz)
    if baz_range[0] < baz_range[1]:
        if baz >= baz_range[0] and baz <= baz_range[1]:
            is_in_range = True
            reverse_require = False
    else:
        if baz >= baz_range[0] or baz <= baz_range[1]:
            is_in_range = True
            reverse_require = True
    return is_in_range, reverse_required


def gen_reversed_egf(inpDir, outDir, egf):
    inpEGF = os.path.join(inpDir, egf)
    sta1 = egf.split('_')[0]
    sta2 = egf.split('_')[1]
    chn = egf.split('_')[2].split('.')[0]
    outEGF = f"{sta2}_{sta1}_{chn}.sac"
    outEGF = os.path.join(outDir, outEGF)
    st = read(inpEGF,format='SAC')
    st[0].data = st[0].data[::-1]
    st[0].write(outEGF,format='SAC')
    inpHeaders = read_sac_headers(inpDir, egf)
    outHeaders = dict()
    outHeaders['stla'] = inpHeaders['evla']
    outHeaders['stlo'] = inpHeaders['evlo']
    outHeaders['stel'] = inpHeaders['evel']
    outHeaders['evla'] = inpHeaders['stla'] 
    outHeaders['evlo'] = inpHeaders['stlo'] 
    outHeaders['evel'] = inpHeaders['stel']
    outHeaders['kstnm'] = f"{inpHeaders['kstnm'].split('-')[1]}-{inpHeaders['kstnm'].split('-')[0]}"
    outHeaders['knetwk'] = f"{inpHeaders['knetwk'].split('-')[1]}-{inpHeaders['knetwk'].split('-')[0]}"
    write_sac_headers(outDir, outEGF, outHeaders)


def read_sac_headers(basedir, sacfile):
    egf = os.path.join(basedir, sacfile)
    tr = read(egf, headonly=True)[0]
    headers = {}
    headers['kstnm'] = tr.stats.sac.kstnm
    headers['knetwk'] = tr.stats.sac.knetwk
    headers['stla'] = tr.stats.sac.stla
    headers['stlo'] = tr.stats.sac.stlo
    headers['stel'] = tr.stats.sac.stel
    headers['evla'] = tr.stats.sac.evla
    headers['evlo'] = tr.stats.sac.evlo
    headers['evel'] = tr.stats.sac.evel
    return headers


def write_sac_headers(basedir, sacfile, headers):
    egf = os.path.join(basedir, sacfile)
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0",
                f"{SAC}<<EOF",\
                f"r {egf}",\
                f"chnhdr kstnm '{headers['kstnm']}'",\
                f"chnhdr knetwk '{headers['knetwk']}'",\
                f"chnhdr stla {headers['stla']}",\
                f"chnhdr stlo {headers['stlo']}",\
                f"chnhdr stel {headers['stel']}",\
                f"chnhdr evla {headers['evla']}",\
                f"chnhdr evlo {headers['evlo']}",\
                f"chnhdr evel {headers['evel']}",\
                "wh",\
                "w over",\
                "q",\
                "EOF"]
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)

#-----------------#

usage1 = False
usage2 = False
usage3 = False
usage4 = False

if len(sys.argv) == 4:
    usage1 = True
    daily_xcorrs_dir = os.path.abspath(sys.argv[1])
    season_stack_dir = os.path.abspath(sys.argv[2])
    num_months = int(sys.argv[3])
elif len(sys.argv) == 2:
    if sys.argv[1][-4:] == '.pkl':
        usage4 = True
        pickle_file = os.path.abspath(sys.argv[1])
        analysis_dir = os.path.abspath(sys.argv[1][:-4])
    else:
        usage2 = True
        season_stack_dir = os.path.abspath(sys.argv[1])
elif len(sys.argv) == 3:
    usage3 = True
    season_stack_dir = os.path.abspath(sys.argv[1])
else:
    print(f"Error Usage!\n{usage}\n")
    exit()

#====USAGE 1====#
if usage1:
    print('Usage 1: generate season-stacked cross-correlograms.\n\n')
    if os.path.isdir(season_stack_dir):
        print(f"Error Usage 1! 'season_stack_dir' should not exist! This script will create it!\n\n")
        exit()

    if num_months not in [1, 2, 3, 4, 6]:
        print(f"Error Usage 1! 'num_months' should be in [1, 2, 3, 4, 6]\n\n{usage}\n")
        exit()

    season_months, seasons_names = get_seasons(num_months)

    xcorrFolders = []
    xcorrMonth = {}
    for path in glob(f'{daily_xcorrs_dir}/*000000'):
        path =  os.path.basename(path)
        if re.search(xcorr_dir_regex, path):
            xcorrFolders.append(path)
            xcorrMonth[xcorrFolders[-1]] = get_month(xcorrFolders[-1])

    if len(xcorrFolders) == 0:
        print("Error Usage 1! No daily xcorr folder was found!\n\
    Check 'xcorr_dir_regex' parameter.\n\n")
        exit()

    print(' Collecting datasets information ...\n')

    sacfiles = {}
    for xcorrFolder in xcorrFolders:
        sacs = []
        for x in os.listdir(os.path.join(daily_xcorrs_dir, xcorrFolder)):
            if re.search(sacfile_regex, x):
                sacs.append(os.path.basename(x))
        
        if len(sacs) > 0:
            sacfiles[xcorrFolder] = sacs
        else:
            print(f'Error Usage 1! Could not find any sacfile in "{xcorrFolder}"\n\n')
            exit()

    xcorr_uniq = [] #uniq xcorr list for each season
    for i in range(12):
        uniq_list = []
        for xcorrFolder in xcorrFolders:
            if get_month(xcorrFolder) in season_months[i]:
                for sac in sacfiles[xcorrFolder]:
                    if sac not in uniq_list:
                        uniq_list.append(sac)
        xcorr_uniq.append(uniq_list)

    num_xcorr_uniq = []
    for x in xcorr_uniq:
        num_xcorr_uniq.append(len(x))

    report = f" Number of months in each season: {num_months}\n Number of xcorr days: {len(xcorrFolders)}\n Number of xcorrs in each season (min-max): {np.nanmin(num_xcorr_uniq)}-{np.nanmax(num_xcorr_uniq)}\n cross-correlogram dir (input): {daily_xcorrs_dir}\n season-stacked dir (output): {season_stack_dir}\n\n"

    print(f"{report}")

    uin = input("Do you want to continue the season-staking process (y/n)? ")

    if uin.lower() != 'y':
        print("\nExit program!\n")
        exit()

    os.mkdir(season_stack_dir)

    # Start the main process
    for i in range(12):
        print(f"\n\nSTAKING PROCESS FOR SEASON: {seasons_names[i]}\n\n")
        os.mkdir(os.path.join(season_stack_dir,seasons_names[i]))
        c = 0
        for xcorr in xcorr_uniq[i]:
            c += 1
            stacklist = []
            print(f"Season {seasons_names[i]}; xcorr '{xcorr}' ({c} of {len(xcorr_uniq[i])})")
            for xcorrFolder in xcorrFolders:
                if get_month(xcorrFolder) in season_months[i]:
                    if xcorr in sacfiles[xcorrFolder]:
                        stacklist.append(os.path.join(daily_xcorrs_dir,xcorrFolder,xcorr))
            stack(stacklist, os.path.join(season_stack_dir, seasons_names[i], xcorr))

#====USAGE 2====#

if usage2:
    print('Usage 2: group season-stacked cross-correlograms into four azimuthal groups\n\n')

    if not os.path.isdir(season_stack_dir):
        print(f"Error Usage 2! Could not find 'season_stack_dir'!\n\n")
        exit()
    else:
        temp = sorted(os.listdir(season_stack_dir))

    seasons = []
    for i in range(len(temp)):
        if re.search('[0-9][0-9]-[0-9][0-9]',temp[i]) and os.path.isdir(os.path.join(season_stack_dir, temp[i])):
            seasons.append(temp[i])

    uniq_xcorr = []
    for i in range(len(seasons)):
        for fn in os.listdir(os.path.join(season_stack_dir, f'{seasons[i]}')):
            if fn not in uniq_xcorr and re.search(sacfile_regex, fn):
                uniq_xcorr.append(fn)

    num_seasons = len(seasons)
    num_uniq_xcorr = len(uniq_xcorr)

    if num_seasons == 0:
        print(f'Error Usage 2! Could not find season directories ("??-??").\n')
        exit()

    if num_uniq_xcorr == 0:
        print(f'Error Usage 2! Could not find any sac file in season directories ("*.sac").\n')
        exit()

    report = f'  Number of seasons: {num_seasons}\n  Number of cross-correlograms: {num_uniq_xcorr}\n  Input directory: {season_stack_dir}\n\n'

    print(report)

    uin = input("Do you want to continue grouping season-stacked cross-correlograms based on azimuths (y/n)? ")

    if uin.lower() == 'y':
        print("\n")
    else:
        print("\n\nExit program!\n")
        exit()

    if general_directions == False and additional_direction == False:
        print('Error! Both "general_directions" and "additional_direction" parameters are set to False! Check the "Adjustable Parameters".\n')
        exit()

    opposite_direction  = {'N':'S', 'NE':'SW', 'E':'W', 'SE':'NW', 'S':'N', 'SW':'NE', 'W':'E', 'NW':'SE'}

    if general_directions:
        # create directories    
        for x in ['N','NE','E','SE','S','SW','W','NW']:
            dirname = os.path.abspath(f'{season_stack_dir}_{x}')
            if os.path.isdir(dirname):
                shutil.rmtree(dirname)

            os.mkdir(dirname)
            for season in seasons:
                os.mkdir(os.path.join(dirname, season))

        for season in seasons:
            i = 0
            for xcorr in uniq_xcorr:
                i += 1
                print(f'  Season: {season}; progress: %.0f%s' %((i/num_uniq_xcorr)*100, '%'), end='   \r')
                sacfile = os.path.join(season_stack_dir, season, xcorr)
                if os.path.isfile(sacfile):
                    direction1 = get_baz_direction(sacfile)
                    dst = os.path.join(f'{season_stack_dir}_{direction1}', season, xcorr)
                    shutil.copyfile(sacfile, dst)
                    # for opposite direction (reversed signal)
                    direction2 = opposite_direction[direction1]
                    inpDir = os.path.join(season_stack_dir, season)
                    outDir = os.path.join(f'{season_stack_dir}_{direction2}', season)
                    gen_reversed_egf(inpDir, outDir, xcorr)

    if additional_direction:
        print(f'\n  Additional backazimuth range is enabled: {additional_baz_range}')
        #create directories
        dirname = os.path.abspath(f'{season_stack_dir}_{additional_baz_range[0]}-{additional_baz_range[1]}')
        if os.path.isdir(dirname):
            shutil.rmtree(dirname)
        os.mkdir(dirname)
        for season in seasons:
            os.mkdir(os.path.join(dirname, season))

        for season in seasons:
            i = 0
            for xcorr in uniq_xcorr:
                i += 1
                print(f'  Season: {season}; progress: %.0f%s' %((i/num_uniq_xcorr)*100, '%'), end='   \r')
                sacfile = os.path.join(season_stack_dir, season, xcorr)
                if os.path.isfile(sacfile):
                    is_in_range, reverse_required = is_baz_in_range(XXX)
                    if is_in_range:
                        if reverse_required:
                            gen_reversed_egf(season_stack_dir, dirname, xcorr)
                        else:
                            dst = os.path.join(f'{season_stack_dir}_{direction}', season, xcorr)
                            shutil.copyfile(sacfile, dst)


#====USAGE 3====#
if usage3:
    print('Usage 3: Generate the analysis pickle file.\n\n')
    if not os.path.isdir(season_stack_dir):
        print(f'Error Usage 3! Could not find "season_stack_dir"!\n{usage}\n')
        exit()
    else:
        temp = sorted(os.listdir(season_stack_dir))

    seasons = []
    ylabels = []
    months = ['January', 'Febuary', 'March', 'April', 'May',\
             'June', 'July', 'August', 'September', 'October', 'November', 'December']

    for i in range(len(temp)):
        if re.search('[0-9][0-9]-[0-9][0-9]',temp[i]) and os.path.isdir(os.path.join(season_stack_dir, temp[i])):
            seasons.append(temp[i])
            i1 = int(temp[i].split('-')[0])-1
            i2 = int(temp[i].split('-')[1])-1
            ylabels.append(f'{months[i1][0:3]}-{months[i2][0:3]}')

    uniq_xcorr = []
    for i in range(len(seasons)):
        for fn in os.listdir(os.path.join(season_stack_dir, f'{seasons[i]}')):
            if fn not in uniq_xcorr and re.search(sacfile_regex, fn):
                uniq_xcorr.append(fn)

    num_seasons = len(seasons)
    num_uniq_xcorr = len(uniq_xcorr)

    if num_seasons == 0:
        print(f'Error Usage 3! Could not find season directories ("??-??")\n')
        exit()

    if num_uniq_xcorr == 0:
        print(f'Error Usage 3! Could not find any sac file in season directories ("*.sac")\n')
        exit()

    if bp:
        pickle_file = f"{os.path.abspath(sys.argv[2])}_{bandpass_prd[0]}-{bandpass_prd[1]}s.pkl"
    else:
        pickle_file = f"{os.path.abspath(sys.argv[2])}.pkl"

    if bp:
        print(f"WARNING! This sript will perform bandpass filtering before the analysis.\n\n")

    report = f'  Number of seasons: {num_seasons}\n  Number of cross-correlograms: {num_uniq_xcorr}\n  Input directory: {season_stack_dir}\n  Output pickle file: {pickle_file}\n\n'

    print(report)


    uin = input("Do you want to continue generating the final results (y/n)? ")

    if uin.lower() == 'y':
        print("\n")
    else:
        print("\n\nExit program!\n")
        exit()


    # Analysis of xcorrs
    # collect data
    seasons = sorted(seasons)
    uniq_xcorr = sorted(uniq_xcorr)
    snr_sym_xcorr = []
    snr_causal_xcorr = []
    snr_acausal_xcorr = []
    nstack_xcorr = []
    amps_xcorr = []
    times_xcorr = []
    i = 0
    print("Analysis of cross-correlograms...\n")
    for xcorr in uniq_xcorr:
        i += 1
        print(f"  collecting data ({i} of {num_uniq_xcorr}):", xcorr)
        snr = []
        snr_causal = []
        snr_acausal = []
        nstack = []
        amps = []
        times = []
        for season in seasons:
            if xcorr in os.listdir(os.path.join(season_stack_dir, season)):
                sf = os.path.join(season_stack_dir, season, xcorr)
                st = read(sf, headonly=True)
                nstack.append(int(st[0].stats.sac.kevnm))
                sfcut = os.path.join(season_stack_dir, 'sfcut.tmp')
                sym = os.path.join(season_stack_dir, 'sym.tmp')
                causal = os.path.join(season_stack_dir, 'causal.tmp')
                acausal = os.path.join(season_stack_dir, 'acausal.tmp')
                signal = os.path.join(season_stack_dir, 'signal_sym.tmp')
                noise = os.path.join(season_stack_dir, 'noise_sym.tmp')
                signal_causal = os.path.join(season_stack_dir, 'signal_causal.tmp')
                noise_causal = os.path.join(season_stack_dir, 'noise_causal.tmp')
                signal_acausal = os.path.join(season_stack_dir, 'signal_acausal.tmp')
                noise_acausal = os.path.join(season_stack_dir, 'noise_acausal.tmp')
                signal_window = get_signal_window_times(sf)
                noise_window = get_noise_window_times(sf)
                sym_sac(sf, sym)
                causal_sac(sf, causal)
                acausal_sac(sf, acausal)
                cut_sac(sf, sfcut, -seism_cut, seism_cut)
                cut_sac(sym, signal, signal_window[0], signal_window[1])
                cut_sac(sym, noise, noise_window[0], noise_window[1])
                cut_sac(causal, signal_causal, signal_window[0], signal_window[1])
                cut_sac(causal, noise_causal, noise_window[0], noise_window[1])
                cut_sac(acausal, signal_acausal, signal_window[0], signal_window[1])
                cut_sac(acausal, noise_acausal, noise_window[0], noise_window[1])
                snr.append(calc_snr(get_sac_data(signal)[0], get_sac_data(noise)[0]))
                snr_causal.append(calc_snr(get_sac_data(signal_causal)[0], get_sac_data(noise_causal)[0]))
                snr_acausal.append(calc_snr(get_sac_data(signal_acausal)[0], get_sac_data(noise_acausal)[0]))
                amps.append(get_sac_data(sfcut)[0])
                times.append(get_sac_data(sfcut)[1])
            else:
                snr.append(np.nan)
                snr_causal.append(np.nan)
                snr_acausal.append(np.nan)
                nstack.append(np.nan)
                amps.append(np.nan)
                times.append(np.nan) 

        if correct_snr:
            for j in range(len(snr)):
                if snr[j] != np.nan:
                    snr[j] = correct_snr_value(snr[j], nstack[j], np.nanmean(nstack))
                    snr_causal[j] = correct_snr_value(snr_causal[j], nstack[j], np.nanmean(nstack))
                    snr_acausal[j] = correct_snr_value(snr_acausal[j], nstack[j], np.nanmean(nstack))

        snr_sym_xcorr.append(snr)
        snr_causal_xcorr.append(snr_causal)
        snr_acausal_xcorr.append(snr_acausal)
        nstack_xcorr.append(nstack)
        amps_xcorr.append(amps)
        times_xcorr.append(times)

    os.remove(sfcut)
    os.remove(sym)
    os.remove(signal)
    os.remove(noise)
    os.remove(causal)
    os.remove(acausal)
    os.remove(signal_causal)
    os.remove(noise_causal)
    os.remove(signal_acausal)
    os.remove(noise_acausal)

    # write into pickle file
    print('\n')
    print('Writing data into pickle file ...', end='\r')
    is_bp = []
    seasons_for_pkl = [] # lists sould have the same lengths; this will do the trick!
    for i in range(num_uniq_xcorr):
        seasons_for_pkl.append([])
        is_bp.append([])
    seasons_for_pkl[0] = seasons
    seasons_for_pkl[1] = ylabels
    if bp:
        is_bp[0] = [bp, bandpass_prd[0], bandpass_prd[1]]
    else:
        is_bp[0] = [bp]

    dataset = {"is_bp":is_bp,\
               "seasons":seasons_for_pkl,\
               "uniq_xcorr":uniq_xcorr,\
               "snr_sym_xcorr":snr_sym_xcorr,\
               "snr_causal_xcorr":snr_causal_xcorr,\
               "snr_acausal_xcorr":snr_acausal_xcorr,\
               "nstack_xcorr":nstack_xcorr,\
               "amps_xcorr":amps_xcorr,\
               "times_xcorr":times_xcorr}
    dataset = pd.DataFrame(dataset).reset_index()
    dataset.to_pickle(f'{pickle_file}')
    print('Writing data into pickle file ... Done!')


#====USAGE 4====#
if usage4:
    print('Usage 4: generate seasonality analysis plots.\n\n')
    print("  Reading 'pickle_file' ... ", end='   \r')
    try:
        dataset = pd.read_pickle(pickle_file)
        bp = dataset["is_bp"][0][0]
        if bp:
            bandpass_prd = [dataset["is_bp"][0][1], dataset["is_bp"][0][2]]
        seasons = dataset["seasons"][0]
        ylabels = dataset["seasons"][1]
        uniq_xcorr = dataset["uniq_xcorr"]
        snr_sym_xcorr = dataset["snr_sym_xcorr"]
        snr_causal_xcorr = dataset["snr_causal_xcorr"]
        snr_acausal_xcorr = dataset["snr_acausal_xcorr"]
        nstack_xcorr = dataset["nstack_xcorr"]
        amps_xcorr = dataset["amps_xcorr"]
        times_xcorr = dataset["times_xcorr"]
    except Exception as e:
        print(f"\n\nError reading pickle file!\n{e}\n")
        exit()

    num_uniq_xcorr = len(uniq_xcorr)
    num_seasons = len(seasons)

    print("  Reading 'pickle_file' ... Done!")

    report = f'  Number of seasons: {num_seasons}\n  Number of cross-correlograms: {num_uniq_xcorr}\n  Output analysis directory: {analysis_dir}\n\n'

    print(report)

    uin = input("Do you want to continue generating the final results (y/n)? ")

    if uin.lower() == 'y':
        print("\n")
    else:
        print("\n\nExit program!\n")
        exit()

    if not os.path.isdir(analysis_dir):
        os.mkdir(analysis_dir)

    if bp:
        xcorrs_analysis_dir = os.path.join(analysis_dir,f"seasonality_analysis_EGFs_{bandpass_prd[0]}-{bandpass_prd[1]}s")
    else:
        xcorrs_analysis_dir = os.path.join(analysis_dir,"seasonality_analysis_EGFs_unfiltered")
    # start the analysis, generate plots
    if station_analysis:
        print("\n Seasonality analysis of the stations.\n")

        if not os.path.isdir(os.path.join(analysis_dir,xcorrs_analysis_dir)):
            os.mkdir(xcorrs_analysis_dir)

        for i in range(num_uniq_xcorr):
            print(f"  generating plot for station {i+1} of {num_uniq_xcorr}")
            fn = open(os.path.join(xcorrs_analysis_dir, f"{uniq_xcorr[i].split('.sac')[0]}.dat"), 'w')
            fn.write("%12s %8s %7s %7s %7s %7s %7s\n" %('EGF', '#seasons', 'min_snr', 'max_snr', 'avg_snr', 'med_snr', 'std_snr'))
            fn.write("%12s %8d %7.3f %7.3f %7.3f %7.3f %7.3f\n\n" \
                %(uniq_xcorr[i].split('.sac')[0], num_seasons-snr_sym_xcorr[i].count(np.nan), np.nanmin(snr_sym_xcorr[i]), np.nanmax(snr_sym_xcorr[i]), np.nanmean(snr_sym_xcorr[i]), np.nanmedian(snr_sym_xcorr[i]), np.nanstd(snr_sym_xcorr[i])))
            pdf = os.path.join(xcorrs_analysis_dir, f"{uniq_xcorr[i].split('.sac')[0]}.pdf")
            sns.set_style('white')
            sns.set_context(sns_context)
            f=plt.figure(figsize=(figsize*2.5,figsize))
            ax1=plt.subplot2grid((50, 90), (0, 0),rowspan=50, colspan=30)
            fn.write("%7s %6s %6s\n" %('season','#stack','snr'))
            for j in range(num_seasons):
                if np.isnan(snr_sym_xcorr[i][j]):
                    pass
                else:
                    fn.write("%7s %6d %6.3f\n" %(ylabels[j], nstack_xcorr[i][j], snr_sym_xcorr[i][j]))
                    amps = np.divide(amps_xcorr[i][j], np.max(np.abs(amps_xcorr[i][j])))
                    amps = np.multiply(amps, seismogram_amp_factor)
                    amps = np.multiply(amps, snr_sym_xcorr[i][j]/np.nanmax(snr_sym_xcorr[i]))
                    amps = np.add(amps, j)
                    plt.plot(times_xcorr[i][j], amps, linewidth=seismogram_line_width, color='k')

            plt.yticks(np.arange(len(ylabels)), ylabels)
            plt.ylim(-1, len(ylabels))
            plt.ylabel('Seasons')
            plt.xlabel('Correlation lag (s)')
            if bp:
                plt.title(f"Seasonal variations ({uniq_xcorr[i].split('.sac')[0]}; {bandpass_prd[0]}-{bandpass_prd[1]} s)")
            else:
                plt.title(f"Seasonal variations ({uniq_xcorr[i].split('.sac')[0]})")

            ax2=plt.subplot2grid((50, 90), (0, 35),rowspan=50, colspan=15)
            ax2.barh(range(num_seasons), snr_sym_xcorr[i], align='center')
            plt.yticks(np.arange(len(ylabels)), ylabels)
            plt.ylim(-1, len(ylabels))
            plt.xlabel('SNR value')
            if correct_snr:
                plt.title(f"Symmetrized SNR (corrected)")
            else:
                plt.title(f"Symmetrized SNR")

            ax3=plt.subplot2grid((50, 90), (0, 55),rowspan=50, colspan=15)
            ax3.barh(range(num_seasons), snr_causal_xcorr[i], align='center')
            plt.yticks(np.arange(len(ylabels)), ylabels)
            plt.ylim(-1, len(ylabels))
            plt.xlabel('SNR value')
            if correct_snr:
                plt.title(f"Causal SNR (corrected)")
            else:
                plt.title(f"Causal SNR")

            ax3=plt.subplot2grid((50, 90), (0, 75),rowspan=50, colspan=15)
            ax3.barh(range(num_seasons), snr_acausal_xcorr[i], align='center')
            plt.yticks(np.arange(len(ylabels)), ylabels)
            plt.ylim(-1, len(ylabels))
            plt.xlabel('SNR value')
            if correct_snr:
                plt.title(f"Acausal SNR (corrected)")
            else:
                plt.title(f"Acausal SNR")

            plt.savefig(pdf,dpi=figure_dpi)
            plt.close()
            fn.close()

    # analysis of the entire region
    selected_seasons = []
    for i in range(num_seasons):
        if i in selected_season_index:
            selected_seasons.append(ylabels[i])

    print("\nSeasonality analysis of the entire region:\n")
    if bp:
        reg_analysis_dir = os.path.join(analysis_dir,f"seasonality_analysis_region_{bandpass_prd[0]}-{bandpass_prd[1]}s")
    else:
        reg_analysis_dir = os.path.join(analysis_dir,"seasonality_analysis_region_unfiltered")
    
    if not os.path.isdir(os.path.join(analysis_dir,reg_analysis_dir)):
        os.mkdir(reg_analysis_dir)

    # WRITE TXT REPORTS

    snr_sym_txt = open(os.path.join(reg_analysis_dir, 'snr_sym_seasons.dat'), 'w')
    snr_acausal_txt = open(os.path.join(reg_analysis_dir, 'snr_acausal_seasons.dat'), 'w')
    snr_causal_txt = open(os.path.join(reg_analysis_dir, 'snr_causal_seasons.dat'), 'w')
    snr_sym_txt.write("%7s %5s %7s %7s %7s %7s %7s\n" %('season', '#EGFs', 'min_snr', 'max_snr', 'avg_snr', 'med_snr', 'std_snr'))
    snr_acausal_txt.write("%7s %5s %7s %7s %7s %7s %7s\n" %('season', '#EGFs', 'min_snr', 'max_snr', 'avg_snr', 'med_snr', 'std_snr'))
    snr_causal_txt.write("%7s %5s %7s %7s %7s %7s %7s\n" %('season', '#EGFs', 'min_snr', 'max_snr', 'avg_snr', 'med_snr', 'std_snr'))
    snr_sym_seasons = {}
    snr_acausal_seasons = {}
    snr_causal_seasons = {}
    for i in range(len(seasons)):
        print(f"  processing season {i+1} of {len(seasons)}")
        snr_sym = []
        snr_causal = []
        snr_acausal = []
        for j in range(len(uniq_xcorr)):
            snr_sym.append(snr_sym_xcorr[j][i])
            snr_acausal.append(snr_acausal_xcorr[j][i])
            snr_causal.append(snr_causal_xcorr[j][i])
        snr_sym_seasons[f'{ylabels[i]}'] = snr_sym
        snr_acausal_seasons[f'{ylabels[i]}'] = snr_acausal
        snr_causal_seasons[f'{ylabels[i]}'] = snr_causal
        snr_sym_txt.write(f"%7s %5d %7.3f %7.3f %7.3f %7.3f %7.3f\n" %(ylabels[i], len(snr_sym)-snr_sym.count(np.nan),np.nanmin(snr_sym), np.nanmax(snr_sym), np.nanmean(snr_sym), np.nanmedian(snr_sym), np.nanstd(snr_sym)))
        snr_acausal_txt.write(f"%7s %5d %7.3f %7.3f %7.3f %7.3f %7.3f\n" %(ylabels[i], len(snr_acausal)-snr_acausal.count(np.nan),np.nanmin(snr_acausal), np.nanmax(snr_acausal), np.nanmean(snr_acausal), np.nanmedian(snr_acausal), np.nanstd(snr_acausal)))
        snr_causal_txt.write(f"%7s %5d %7.3f %7.3f %7.3f %7.3f %7.3f\n" %(ylabels[i], len(snr_causal)-snr_causal.count(np.nan),np.nanmin(snr_causal), np.nanmax(snr_causal), np.nanmean(snr_causal), np.nanmedian(snr_causal), np.nanstd(snr_causal)))
    snr_sym_txt.close()
    snr_acausal_txt.close()
    snr_causal_txt.close()

    df_sym = pd.DataFrame(snr_sym_seasons)
    df_sym = df_sym[selected_seasons]
    df_causal = pd.DataFrame(snr_causal_seasons)
    df_causal = df_causal[selected_seasons]
    df_acausal = pd.DataFrame(snr_acausal_seasons)
    df_acausal = df_acausal[selected_seasons]

    # BOXPLOTS

    # symmetric SNR
    pdf = os.path.join(reg_analysis_dir, "snr_sym_boxplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    f=plt.figure(figsize=(figsize*1.5,figsize))
    ax = sns.boxplot(data=df_sym, color='white')
    # change the color (do not want it to be so colorful!):
    myColor = (0.12,0.46,0.70,1)
    for i,box in enumerate(ax.artists):
        box.set_edgecolor(myColor)
        box.set_facecolor('white')
        # iterate over whiskers and median lines
        for j in range(6*i,6*(i+1)):
             ax.lines[j].set_color(myColor)
    plt.ylabel('SNR value')
    if correct_snr:
        plt.title(f"Seasonal variations of SNR (corrected) values")
    else:
        plt.title(f"Seasonal variations of SNR values")
    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()

    # acausal SNR
    pdf = os.path.join(reg_analysis_dir, "snr_acausal_boxplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    f=plt.figure(figsize=(figsize*1.5,figsize))
    ax = sns.boxplot(data=df_acausal, color='white')
    # change the color (do not want it to be so colorful!):
    myColor = (0.12,0.46,0.70,1)
    for i,box in enumerate(ax.artists):
        box.set_edgecolor(myColor)
        box.set_facecolor('white')
        # iterate over whiskers and median lines
        for j in range(6*i,6*(i+1)):
             ax.lines[j].set_color(myColor)
    plt.ylabel('SNR value')
    if correct_snr:
        plt.title(f"Seasonal variations of SNR (corrected) values")
    else:
        plt.title(f"Seasonal variations of SNR values")
    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()

    # causal SNR
    pdf = os.path.join(reg_analysis_dir, "snr_causal_boxplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    f=plt.figure(figsize=(figsize*1.5,figsize))
    ax = sns.boxplot(data=df_causal, color='white')
    # change the color (do not want it to be so colorful!):
    myColor = (0.12,0.46,0.70,1)
    for i,box in enumerate(ax.artists):
        box.set_edgecolor(myColor)
        box.set_facecolor('white')
        # iterate over whiskers and median lines
        for j in range(6*i,6*(i+1)):
             ax.lines[j].set_color(myColor)
    plt.ylabel('SNR value')
    if correct_snr:
        plt.title(f"Seasonal variations of SNR (corrected) values")
    else:
        plt.title(f"Seasonal variations of SNR values")
    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()


    # SCATTER PLOT

    # symmetric SNR
    f=plt.figure(figsize=(figsize*1.5,figsize))
    pdf = os.path.join(reg_analysis_dir, "snr_sym_scatterplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    plt.ylabel('SNR value')
    if scatter_plot_errors:
        sns.pointplot(data=df_sym, linestyles="--", capsize=.2, ci='sd')
    else:
        sns.pointplot(data=df_sym, linestyles="--", ci=None)
    if correct_snr:
        plt.title(f"Seasonal variations of mean SNR (corrected)")
    else:
        plt.title(f"Seasonal variations of mean SNR")
    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()

    # acausal SNR
    f=plt.figure(figsize=(figsize*1.5,figsize))
    pdf = os.path.join(reg_analysis_dir, "snr_acausal_scatterplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    plt.ylabel('SNR value')
    if scatter_plot_errors:
        sns.pointplot(data=df_acausal, linestyles="--", capsize=.2, ci='sd')
    else:
        sns.pointplot(data=df_acausal, linestyles="--", ci=None)
    if correct_snr:
        plt.title(f"Seasonal variations of mean SNR (corrected)")
    else:
        plt.title(f"Seasonal variations of mean SNR")

    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()

    # causal SNR
    f=plt.figure(figsize=(figsize*1.5,figsize))
    pdf = os.path.join(reg_analysis_dir, "snr_causal_scatterplot.pdf")
    sns.set_style('ticks')
    sns.set_context(sns_context)
    plt.ylabel('SNR value')
    if scatter_plot_errors:
        sns.pointplot(data=df_causal, linestyles="--", capsize=.2, ci='sd')
    else:
        sns.pointplot(data=df_causal, linestyles="--", ci=None)
    if correct_snr:
        plt.title(f"Seasonal variations of mean SNR (corrected)")
    else:
        plt.title(f"Seasonal variations of mean SNR")

    plt.savefig(pdf,dpi=figure_dpi)
    plt.close()

print("\n\nDone!\n")
