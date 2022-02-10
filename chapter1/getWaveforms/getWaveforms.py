#!/usr/bin/env python3
import subprocess
import sys
import os
about = "This script uses obspy FDSN and IRIS FetchData to download event waveforms."
usage = '''
USAGE: python3  getWaveforms.py <netsta> <events> <download dir> <user:pass>

 <netsta>: a text file with 2 columns:
   1)network  2)station

 <events>: a text file with at least 7 columns:
   1)evtDate 2)evtTime 3)evla 4)evlo 5)evdp 6)mag 7)magType

 <user:pass> is optional, in username:password format for downloading restricted data

 Similar to jweed event list:
   evtDate: yyyy-mm-dd
   evtTime: hh:mm:ss.sss
'''
# Coded by omid.bagherpur@gmail.com
# UPDATE: 10 June 2020
#=====Adjustable Parameters=====#
duration = 2*60*60  # in sec
channels = ["HHE", "HHN", "HHZ"]  # list of channels to download
# list of station location codes to download; [""] for no location code
locations = ["", "00", "10"]
shift = -500  # in sec; e.g. if set to -1000, sac file begin time will be 1000 sec earlier than event origin time

SAC = "/usr/local/sac/bin/sac"  # path to SAC software
# path to IRIS 'FetchData' perl script
FetchData_Script = './FetchData-2018.337'
# a list of data centres (see https://docs.obspy.org/packages/obspy.clients.fdsn.html)
FDSN_data_centres = ["IRIS"]
# a list in [minLat, maxLat] format (limiting station location)
longitude_range = [-180, 180]
# a list in [minLon, maxLon] format (limiting station location)
latitude_range = [-90, 90]

# Processing parameters:
# Notes from Omid:
#  1) rtrend command in SAC is equivalent to detrend_method='demean' here.
#  2) taper command in SAC is equivalent to max_taper=0 here.
#  3) 'spline' method gives the best detrending results (visually), but results highly depend on dspline parameter.
#      My tests indicate dspline=duration*10 gives the best results (hardwired in the code)
# between 0 and 0.5; I recommend a very small number (0.001-0.01)
max_taper = 0.005
# options: (1) 'spline', (2) 'polynomial' (3) 'demean', (4) 'linear'; I recommend 'spline' method
detrend_method = 'spline'
# utilised only if detrend_method is either set to 'spline' or 'polynomial', I recommend 3-5
detrend_order = 4
#===============================#
os.system('clear')
print(about)

if len(sys.argv) < 4:
    print(f"\nError! This Script at least requires 3 inputs.\n{usage}")
    exit()
else:
    stalist = os.path.abspath(sys.argv[1])
    eventlist = os.path.abspath(sys.argv[2])
    outdir = os.path.abspath(sys.argv[3])

authentication = False
if len(sys.argv) == 5:
    authentication = True
    try:
        username = str(sys.argv[4]).split(':')[0]
        password = str(sys.argv[4]).split(':')[1]
    except:
        print(f"\nError reading <user:pass>!\n{usage}")
        exit()

if not os.path.isfile(FetchData_Script):
    print(f"Error!\n Could not find IRIS 'FetchData' perl script\n\nVisit http://service.iris.edu/clients/ to download the script.\n\n")
    exit()
else:
    FetchData_Script = os.path.abspath(FetchData_Script)

if not os.path.isfile(SAC):
    print(f"Error! Path to SAC software does not exist!\nCheck 'Adjustable Parameters'\n\n")
    exit()

try:
    import obspy
    import re
    import shutil
    import numpy as np
    from obspy import UTCDateTime
    from obspy.clients.fdsn.client import Client
    from obspy.clients.fdsn.mass_downloader import RectangularDomain, Restrictions, MassDownloader
except ImportError as e:
    print(f'\nError! {e}\n')
    exit()

if not os.path.isfile(stalist):
    print(f"\nError! <net sta> file does not exist.\n{usage}")
    exit()
else:
    stations = []
    networks = []
    with open(stalist, 'r') as stalist:
        for line in stalist:
            try:
                networks.append(line.split()[0])
                stations.append(line.split()[1])
            except:
                print(f"\nError! <netsta> format is not correct.\n{usage}")
                exit()

uniq_networks = []
for x in networks:
    if x not in uniq_networks:
        uniq_networks.append(x)


if not os.path.isfile(eventlist):
    print(f"\nError! <events> file does not exist.\n{usage}")
    exit()
else:
    event_date = []
    event_time = []
    event_datetime = []
    event_origin = []
    event_timestamp = []
    event_lat = []
    event_lon = []
    event_dep = []
    event_mag = []
    event_magType = []
    with open(eventlist, 'r') as eventlist:
        for line in eventlist:
            try:
                event_date.append(f"{line.split()[0]}")
                event_time.append(f"{line.split()[1]}")
                datetime = f"{line.split()[0]}T{line.split()[1]}"
                utcdatetime = UTCDateTime(datetime)
                event_origin.append(utcdatetime)
                utcdatetime += shift
                event_datetime.append(utcdatetime)
                event_timestamp.append(int(event_datetime[-1].timestamp))
                event_lat.append(float(line.split()[2]))
                event_lon.append(float(line.split()[3]))
                event_dep.append(float(line.split()[4]))
                event_mag.append(float(line.split()[5]))
                event_magType.append(line.split()[6])
            except Exception as e:
                print(f"{e}\nError! <events> format is not correct.\n{usage}")
                exit()

if not os.path.isdir(outdir):
    print(f"\nError! <download dir> directory does not exist.\n{usage}")
    exit()

#=====FUNCTIONS=====#


# returns 2 lists of start and end times [t1, t2] to be used in FetchData and FDSN methods
def event_timeRange(events, duration):
    timeRange = []
    utcTimeRange = []
    for eventStart in events:
        eventEnd = eventStart+duration
        t1 = f"%4s-%02d-%02d,%02d:%02d:%02d.0000" % (str(eventStart.year), eventStart.month, eventStart.day, eventStart.hour, eventStart.minute, eventStart.second)
        t2 = f"%4s-%02d-%02d,%02d:%02d:%02d.0000" % (str(eventEnd.year), eventEnd.month, eventEnd.day, eventEnd.hour, eventEnd.minute, eventEnd.second)
        t3 = f"%4s-%02d-%02dT%02d:%02d:%02d.0000" % (str(eventStart.year), eventStart.month, eventStart.day, eventStart.hour, eventStart.minute, eventStart.second)
        t4 = f"%4s-%02d-%02dT%02d:%02d:%02d.0000" % (str(eventEnd.year), eventEnd.month, eventEnd.day, eventEnd.hour, eventEnd.minute, eventEnd.second)
        timeRange.append([t1, t2])
        utcTimeRange.append([t3, t4])
    return timeRange, utcTimeRange


def getxml(sta, net, chn, outfile):
    if authentication:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -a {username}:{password} -X {outfile} -v\n"
    else:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -X {outfile} -v\n"
    subprocess.call(shell_cmd, shell=True)


def check_IRIS_availability(sta, net, chn, loc, t1, t2, longitude_range, latitude_range):
    # a trick to find out if data is available: If metafile is created, data is available!
    metafile = os.path.join(outdir, 'meta.tmp')
    if os.path.isfile(metafile):
        os.remove(metafile)
    if authentication:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -L {loc} -s {t1} -e {t2} --lon {longitude_range[0]}:{longitude_range[1]} --lat {latitude_range[0]}:{latitude_range[1]} -a {username}:{password} -m {metafile} -q\n"
    else:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -L {loc} -s {t1} -e {t2} --lon {longitude_range[0]}:{longitude_range[1]} --lat {latitude_range[0]}:{latitude_range[1]} -m {metafile} -q\n"
    subprocess.call(shell_cmd, shell=True)
    if os.path.isfile(metafile):
        os.remove(metafile)
        return True
    else:
        return False


def get_IRIS_data(sta, net, chn, loc, t1, t2, outfile, longitude_range, latitude_range):
    if authentication:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -L {loc} -s {t1} -e {t2} --lon {longitude_range[0]}:{longitude_range[1]} --lat {latitude_range[0]}:{latitude_range[1]} -a {username}:{password} -o {outfile} -v\n"
    else:
        shell_cmd = f"perl {FetchData_Script} -S {sta} -N {net} -C {chn} -L {loc} -s {t1} -e {t2} --lon {longitude_range[0]}:{longitude_range[1]} --lat {latitude_range[0]}:{latitude_range[1]} -o {outfile} -v\n"
    subprocess.call(shell_cmd, shell=True)


def write_sac_headers(evla, evlo, evdp, stla, stlo, stel, cmpaz, cmpinc, sacfile):
    shell_cmd = ["export SAC_DISPLAY_COPYRIGHT=0", f"{SAC}<<EOF"]
    shell_cmd.append(f"r {sacfile}")
    shell_cmd.append(f"chnhdr evla {evla}")
    shell_cmd.append(f"chnhdr evlo {evlo}")
    shell_cmd.append(f"chnhdr evdp {evdp}")
    shell_cmd.append(f"chnhdr stla {stla}")
    shell_cmd.append(f"chnhdr stlo {stlo}")
    shell_cmd.append(f"chnhdr stel {stel}")
    shell_cmd.append(f"chnhdr cmpaz {cmpaz}")
    shell_cmd.append(f"chnhdr cmpinc {cmpinc}")
    shell_cmd.append("chnhdr lovrok True")
    shell_cmd.append("chnhdr lcalda True")
    shell_cmd.append(f"w {sacfile}")
    shell_cmd.append('quit')
    shell_cmd.append('EOF')
    shell_cmd = '\n'.join(shell_cmd)
    subprocess.call(shell_cmd, shell=True)

#===================#


print(f"\n Number of stations: {len(stations)}\n Number of networks: {len(uniq_networks)}\n Number of events: {len(event_datetime)}\n Download directoty: '{outdir}'\n")

uans = input("Do you want to continue (y/n)? ")
if uans.lower() == 'y':
    pass
else:
    print("\nExit program!\n\n")
    exit()


domain = RectangularDomain(minlatitude=latitude_range[0], maxlatitude=latitude_range[1],
                           minlongitude=longitude_range[0], maxlongitude=longitude_range[1])
mseed_storage = os.path.join(outdir, "getWaveforms_mseed")
if not os.path.isdir(mseed_storage):
    os.mkdir(mseed_storage)

event_timeRange, event_utcTimeRange = event_timeRange(event_datetime, duration)

i = 0  # counter for events
while i < len(event_timeRange):
    j = 0  # counter for stations
    while j < len(stations):
        for chn in channels:
            for loc in locations:
                os.system('clear')
                print(f"Downloading data for event {i+1} of {len(event_datetime)}, station: '{stations[j]}' ({j+1} of {len(stations)})\n\n")
                # obspy FDSN method
                stationxml_storage = os.path.join(outdir, f"getWaveforms_stationxml_{chn}")
                btime = UTCDateTime(event_utcTimeRange[i][0])
                etime = UTCDateTime(event_utcTimeRange[i][1])
                restrictions = Restrictions(
                    starttime=btime,
                    endtime=etime,
                    chunklength_in_sec=duration,
                    network=networks[j],
                    station=stations[j],
                    location=loc,
                    channel=chn,
                    reject_channels_with_gaps=False,  # we will take care of data fragmentation later!
                    minimum_length=0.0,  # all data is usefull!
                    minimum_interstation_distance_in_m=0)

                for k in range(len(FDSN_data_centres)):
                    if authentication:
                        cl = Client(
                            FDSN_data_centres[k], user=username, password=password)
                        mdl = MassDownloader(providers=[cl])
                        mdl.download(domain, restrictions, mseed_storage=mseed_storage,
                                     stationxml_storage=stationxml_storage, print_report=True)
                    else:
                        mdl = MassDownloader(providers=[FDSN_data_centres[k]])
                        mdl.download(domain, restrictions, mseed_storage=mseed_storage,
                                     stationxml_storage=stationxml_storage, print_report=True)
                # IRIS FetchData method:
                fileName = "%s.%s.%s.%s__%4d%02d%02dT%02d%02d%02dZ__%4d%02d%02dT%02d%02d%02dZ.mseed" % (
                    networks[j], stations[j], loc, chn, btime.year, btime.month, btime.day, btime.hour, btime.minute, btime.second, etime.year, etime.month, etime.day, etime.hour, etime.minute, etime.second)
                if not os.path.isfile(os.path.join(mseed_storage, fileName)):
                    if check_IRIS_availability(stations[j], networks[j], chn, loc, event_timeRange[i][0], event_timeRange[i][1], longitude_range, latitude_range):
                        print(f"\nUsing method 2, IRIS FetchData:\n")
                        get_IRIS_data(stations[j], networks[j], chn, loc, event_timeRange[i][0], event_timeRange[i][1], os.path.join(
                            mseed_storage, fileName), longitude_range, latitude_range)
        j += 1
    i += 1


# FDSN xml data are not reliable in our case! redownloading through IRIS FetchData:
for chn in channels:
    stationxml_storage = os.path.join(outdir, f"getWaveforms_stationxml_{chn}")
    if not os.path.isdir(stationxml_storage):
        os.mkdir(stationxml_storage)
    for i in range(len(stations)):
        print(f"  Downloding xml data for {networks[i]}.{stations[i]}", end="    \r")
        fn0 = f"{networks[i]}.{stations[i]}.xml"
        fn0 = os.path.join(stationxml_storage, fn0)
        if os.path.isfile(fn0):
            os.remove(fn0)
        fn = f"{networks[i]}.{stations[i]}.{chn}"
        fn = os.path.join(stationxml_storage, fn)
        getxml(stations[i], networks[i], chn, fn)
    if len(os.listdir(stationxml_storage)) == 0:
        shutil.rmtree(stationxml_storage)


os.system('clear')

if os.path.isdir(mseed_storage):
    mseeds = os.listdir(mseed_storage)
    nData = len(mseeds)
else:
    print("\n\n Error! No mseed data were available to download!\n\n")
    exit()


# generate the list of stationxml files
stationxmls = []
for chn in channels:
    xmllist = []
    try:
        xmllist = os.listdir(os.path.join(outdir, f"getWaveforms_stationxml_{chn}"))
        for item in xmllist:
            stationxmls.append(f"getWaveforms_stationxml_{chn}/{item}")
    except:
        pass


sacfiles_dir = os.path.join(outdir, f"getWaveforms_sacfiles")
print("\n Download is complete!\n\n")
if not os.path.isdir(sacfiles_dir):
    os.mkdir(sacfiles_dir)

# add sac headers to mseed data then output sac file
event_index = []
stationxml_index = []
for i in range(nData):
    print(f"  Extracting sac file: {mseeds[i]}")
    mseed = os.path.join(outdir, mseed_storage, mseeds[i])
    loc = mseeds[i].split('.')[2]
    st = obspy.read(mseed)

    if detrend_method == 'spline':
        try:
            st.detrend(detrend_method, order=detrend_order, dspline=864000)
        except:
            st.detrend('demean')
    elif detrend_method == 'polynomial':
        try:
            st.detrend(detrend_method, order=detrend_order)
        except:
            st.detrend('demean')
    else:
        st.detrend(detrend_method)

    st.taper(max_taper)
    if len(st) != 1:
        fs = []
        for k in range(len(st)):
            fs.append(float(st[k].stats['sampling_rate']))

        if len(np.unique(fs)) > 1:
            st.resample(np.round(np.unique(fs).min()))
            
        st.merge(method=1, fill_value=0)

    tr = st[0]

    # find and add event info
    for j in range(len(event_timestamp)):
        delta = abs(event_timestamp[j]-int(tr.stats.starttime.timestamp))
        if delta < 0.1*duration:
            event_index = j
            break

    evtDateTime = event_datetime[event_index]-shift
    event_yy = f"%s" % (str(evtDateTime.year)[2:])
    event_jjj = f"%03d" % (evtDateTime.julday)
    event_hh = f"%02d" % (evtDateTime.hour)
    event_mm = f"%02d" % (evtDateTime.minute)
    event_ss = f"%02d" % (evtDateTime.second)
    event_name = f"{event_yy}{event_jjj}{event_hh}{event_mm}{event_ss}"
    event_dir = os.path.join(sacfiles_dir, event_name)
    if not os.path.isdir(event_dir):
        os.mkdir(event_dir)

    tr.stats.sac = obspy.core.AttribDict()
    #tr.stats.sac.evla = np.float(event_lat[event_index])
    #tr.stats.sac.evlo = np.float(event_lon[event_index])
    #tr.stats.sac.evdp = np.float(event_dep[event_index])
    tr.stats.sac.mag = event_mag[event_index]
    tr.stats.sac.b = shift
    tr.stats.sac.o = 0
    tr.stats.sac.iztype = 11

    if event_magType[event_index].lower() == 'mb':
        magtype = 52
    elif event_magType[event_index].lower() == 'ms':
        magtype = 53
    elif event_magType[event_index].lower() == 'ml':
        magtype = 54
    elif event_magType[event_index].lower() == 'mw':
        magtype = 55
    elif event_magType[event_index].lower() == 'md':
        magtype = 56
    else:
        magtype = 57

    tr.stats.sac.imagtyp = magtype

    # find and add station info
    tr_stxml = f"getWaveforms_stationxml_{tr.stats.channel}/{tr.stats.network}.{tr.stats.station}.{tr.stats.channel}"
    stationxml_index = stationxmls.index(tr_stxml)
    inv = obspy.read_inventory(
        stationxmls[stationxml_index], format="STATIONXML")

    if loc == "":
        sacfile = f"{event_dir}/{event_name}_{tr.stats.station}.{tr.stats.channel}"
    else:
        sacfile = f"{event_dir}/{event_name}_{tr.stats.station}.{loc}.{tr.stats.channel}"

    tr.write(sacfile, format="sac")
    # write sac headers using SAC and not obspy! -> There was issues with saclst reading BAZ ...
    evla = np.float(event_lat[event_index])
    evlo = np.float(event_lon[event_index])
    evdp = np.float(event_dep[event_index])
    stla = np.float(inv[0][0].latitude)
    stlo = np.float(inv[0][0].longitude)
    stel = np.float(inv[0][0].elevation)
    cmpaz = np.float(inv[0][0][0].azimuth)
    cmpinc = np.float(inv[0][0][0].dip)+90
    write_sac_headers(evla, evlo, evdp, stla, stlo,
                      stel, cmpaz, cmpinc,  sacfile)

print("\n\nDone!\n\n")
