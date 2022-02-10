#!/usr/bin/env python3
about='This script uses obspy to generate a list of global events occured in a date range.\n'
usage='''
USAGE: python3 getEvents.py <start-date> <end-date> <min magnitude> <lat0> <lon0>

Note: 1) <start-date> and <end-date> should be
         given in "yyyy-mm-dd" format
      
      2) <lat0> and <lon0> are optional; if given,
         program will output BAZ and GCARC of from this point
'''
#note: missing information is output as xxx
#Coded by omid.bagherpur@gmail.com
#Update: 2019/12/17
#====Adjustable Parameters====#
#define query range:
latitude_range  = [-90, 90]   #[min_lat, max_lat]
longitude_range = [-180, 180] #[min_lon, max_lon]
plot_histograms = 'yes' #'yes' or 'no';only works if user inputs <lat0> and <lon0>
BAZ_bin_size=45 #in degrees
#=============================#
import os,sys
os.system('clear')
print(about)

try:
    import re
    import obspy
    from obspy import UTCDateTime
    from obspy.clients.fdsn.client import Client
except ImportError as e:
    print(f'\nError! {e}\n')
    exit()

extra=0 #a flag for outputing BAZ abd GCdist
if len(sys.argv) > 3:
    start_time = UTCDateTime(f"{sys.argv[1]}T00:00:00")
    end_time   = UTCDateTime(f"{sys.argv[2]}T23:59:59")
    min_magnitude = sys.argv[3]
    if len(sys.argv) == 6:
        extra=1
        try:
            import math
            import numpy as np
            import matplotlib.pyplot as plt
            from geographiclib.geodesic import Geodesic # pip install geographiclib
            from mpl_toolkits.basemap import Basemap as bm #conda install basemap; #conda install basemap-data-hires
        except ImportError as e:
            print(f"{e}\nBAZ and GCArc cannot be calculated!\n")
            exit()
            
        lat0 = sys.argv[4]
        lon0 = sys.argv[5]
else:
    print(f'Error usage!\n{usage}')
    exit()




print("  Acquiring data from IRIS ...",end='\r')

client=Client("IRIS")
cat = client.get_events(starttime=start_time, endtime=end_time, minmagnitude=min_magnitude, minlongitude=longitude_range[0], maxlongitude=longitude_range[1], minlatitude=float(latitude_range[0]), maxlatitude=float(latitude_range[1]))


nEvent=cat.count()

i=0
output_data=[]
event_lat=[]
event_lon=[]
event_baz=[]
event_gca=[]
while i < nEvent:
    origins=str(cat[i].origins[0])
    origins=re.split("\n|\s|,|\=|\:|\(|\)",origins)
    while '' in origins:
        origins.remove('')
    evt_lat   = "%8.4f" %(float(origins[origins.index('latitude')+1]))
    evt_lon   = "%9.4f" %(float(origins[origins.index('longitude')+1]))
    try:
        evt_dep   = "%6.2f" %(float(origins[origins.index('depth')+1])/1000)
    except:
        evt_dep   = "%6s" %('xxx')
    evt_year  = "%4d" %(float(origins[origins.index('UTCDateTime')+1]))
    evt_month = "%02d" %(float(origins[origins.index('UTCDateTime')+2]))
    evt_day   = "%02d" %(float(origins[origins.index('UTCDateTime')+3]))
    evt_hh    = "%02d" %(float(origins[origins.index('UTCDateTime')+4]))
    evt_min   = "%02d" %(float(origins[origins.index('UTCDateTime')+5]))
    try:
        evt_sec   = "%02d" %(float(origins[origins.index('UTCDateTime')+6]))
    except:
        evt_sec   = "00"
    try: #sometime second fraction data is missing!
        evt_sec = f"{evt_sec}.%03d" %(float(origins[origins.index('UTCDateTime')+7][:3]))
    except:
        evt_sec = f"{evt_sec}.000"

    evt_date  = evt_year+'-'+evt_month+'-'+evt_day
    evt_time  = evt_hh+':'+evt_min+':'+evt_sec
    evt_UTCDateTime = UTCDateTime(evt_year+'-'+evt_month+'-'+evt_day+"T"+evt_hh+':'+evt_min+':'+evt_sec)
    evt_julday = "%3d" %(evt_UTCDateTime.julday)

    magnitudes=str(cat[i].magnitudes[0])
    magnitudes=re.split("\n|\s|,|\=|\:|\(|\)",magnitudes)
    while '' in magnitudes:
        magnitudes.remove('')

    evt_mag   = "%3.1f" %(float(magnitudes[magnitudes.index('mag')+1]))
    try:
        evt_mag_type   = "%3s" %(magnitudes[magnitudes.index('magnitude_type')+1][1:-1])
    except:
        evt_mag_type = "%3s" %('xxx')
    
    if extra == 1:
        gcDist_to_ref = Geodesic.WGS84.Inverse(float(lat0),float(lon0),float(evt_lat),float(evt_lon))['s12']
        gcArc_to_ref = "%6.2f" %(gcDist_to_ref/111320)
        baz_to_ref = "%4d" %(Geodesic.WGS84.Inverse(float(lat0),float(lon0),float(evt_lat),float(evt_lon))['azi1'])
        if int(baz_to_ref)<0:
            baz_to_ref= "%4d" %(int(baz_to_ref)+360)

        output_data.append(' '.join([evt_date, evt_time, evt_lat, evt_lon,
                                     evt_dep,evt_mag,evt_mag_type, evt_julday,
                                     baz_to_ref, gcArc_to_ref]))
        event_lat.append(float(evt_lat))
        event_lon.append(float(evt_lon))
        event_baz.append(int(baz_to_ref))
        event_gca.append(float(gcArc_to_ref))
    else:
        output_data.append(' '.join([evt_date, evt_time, evt_lat, evt_lon,
                                     evt_dep,evt_mag,evt_mag_type, evt_julday]))


    

    i+=1
print("  Acquiring data from IRIS ... Done!\n")

#save to events.dat
ouput=open('events.dat','w')
for evt in output_data:
    ouput.write(f"{evt}\n")

months=["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

print(f"  Start date: {start_time.day} {months[int(start_time.month)-1]} {start_time.year}\n  End date:   {end_time.day} {months[int(end_time.month)-1]} {end_time.year}\n  Number of events found: {nEvent}")

if extra == 1:
    print(f"  Reference point (lat, lon): ({lat0}, {lon0})\n\n")
    print(f"'events.dat' was generated in the following format:\n Date, Time, Lat, Lon, Dep(km), Mag, Mag-type, JDay, BAZ, GCARC\n\n")
else:
    print(f"\n'events.dat' was generated in the following format:\n Date, Time, Lat, Lon, Dep(km), Mag, Mag-type, JDay\n\n")

#plot histograms
if extra == 1 and plot_histograms == 'yes':
    print(" Plotting results ...\n")
    
    #GCARC histogram    
    plt.clf()
    f= plt.figure(figsize=(10,8))
    f.suptitle(f'BAZ and GCARC histograms calculated from the blue star (lat: {lat0}, lon: {lon0})\n {nEvent} events of magnitude >{min_magnitude} occurred from {start_time.day} {months[int(start_time.month)-1]} {start_time.year} to {end_time.day} {months[int(end_time.month)-1]} {end_time.year}',x=0.01,y=0.98, ha='left')
    ax1=plt.subplot2grid((5, 7), (1, 0),rowspan=2, colspan=2)
    plt.hist(event_gca)
    plt.xlabel('Great Circle Arc (degrees)')
    
    #BAZ histogram
    degrees=np.asarray(event_baz)
    radians=np.asarray(np.deg2rad(event_baz))
    a, b=np.histogram(degrees, bins=np.arange(0, 360+BAZ_bin_size, BAZ_bin_size))
    centres=np.deg2rad(np.ediff1d(b)//2 + b[:-1])
    ax2=plt.subplot2grid((5, 7), (3, 0), rowspan=2, colspan=2, projection='polar')
    ax2.set_theta_zero_location("N")
    ax2.set_theta_direction(-1)
    #ax2.set_xticklabels(['0','45','90','135','180','225','270','315'])
    bars=ax2.bar(centres, a, bottom=0,width=np.deg2rad(BAZ_bin_size), edgecolor='k')
    for bar in bars:
        bar.set_alpha(0.5)

    #event map
    ax3=plt.subplot2grid((5, 7), (0, 2), rowspan=5, colspan=5)
    map = bm(projection='aeqd',lat_0=lat0,lon_0=lon0,resolution='c')
    map.drawcoastlines(linewidth=0.25)
    map.fillcontinents(color='0.95',lake_color='white',zorder = 0)
    x0,y0=map(float(lon0),float(lat0))
    plt.scatter(float(x0),float(y0),s=300,color='blue',marker='*',zorder = 1,alpha=1.0)
    i=0
    while i<len(event_lat):
        x,y=map(float(event_lon[i]),float(event_lat[i]))
        plt.scatter(float(x),float(y),s=20,c='red',marker='o',alpha=1.0,zorder = 2)
        i+=1
    plt.tight_layout()
    plt.savefig('events.pdf',dpi=300)
    
print("\nDone!\n\n")


