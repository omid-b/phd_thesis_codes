#!/usr/bin/env python3
# This script extracts sac files from mseed data and merges fragmented data (e.g. infamous CNDC mseed files!).
# USAGE: ./mseed2sac.py  <datalist (list of seed files)>  <output directory>
# Coded by omid.bagherpur@gmail.com
# UPDATE: 10 Dec 2019
#===Adjustable Parameters===#
channels = '?H?' #e.g. '?H?' includes BHZ and HHZ components
fill_gap_value = 0 #fill gap value when merging fragmented data
make_event_dirs =  'yes' #'yes' or 'no'; Generating and moving outputs to event directories; It will not remove existing event directories
output_fragmented = 'yes' #'yes' or 'no'; output fragmented files as *.p??
merge_event_threshold = 86400 #'auto' or an integer (in sec); For ambient-noise tomography: 86400 (one day)
taper_max_percentage =  0.001 #between 0 and 0.5; see obspy documentation for taper command; I recommend a very small number (e.g. 0.001)
detrend_type =  'spline'      #options: (1) 'spline', (2) 'demean', (3) 'linear'; I recommend 'spline'
#===========================#
import os, sys
os.system('clear')
print('This script extracts sac files from mseed data while merging fragmented data.')

usage = '''
  USAGE: ./mseed2sac.py  <datalist (seed files)>  <output directory>
'''

if len(sys.argv) != 3:
    print('\nError!\n',usage)
    exit()
else:
    print("\n  Channel(s):    %s\n  Fill gap value: %s\n  Make event directories: %s\n  Output fragmented data: %s\n  merge_event_threshold: %s\n  taper_max_percentage:  %s\n  detrend_type:  %s\n" % (channels,fill_gap_value,make_event_dirs,output_fragmented,merge_event_threshold,taper_max_percentage,detrend_type))        

if os.path.isfile(sys.argv[1]):
    seeds= open(sys.argv[1],'r').read().splitlines()
else:
    print(f'\nError! Could not find "{sys.argv[1]}"\n')
    exit()
    
outdir = os.path.abspath(sys.argv[2])

for seed in seeds:
  if not os.path.isfile(seed):
    print('Error! Could not find "%s"\n' %(seed))
    exit()


try: 
    import numpy as np
    import matplotlib.pyplot as plt
    from fnmatch import filter as wcard
    import obspy, glob, shutil
except ImportError:
    print('Error! Could not import required modules! Check the following:\n  obspy, numpy, matplotlib.pyplot, fnmatch\n')
    exit()

#--functions--#
def find_duplicates(seq,item):
    start_at = -1
    locs = []
    while True:
        try:
            loc = seq.index(item,start_at+1)
        except ValueError:
            break
        else:
            locs.append(loc)
            start_at = loc
    return locs
#------------#
#main code block
uans=input("\n\nDo you want to continue (y/n)? ")
if uans != 'y':
    print('\n\nExit program!\n')
    exit()
else:
    print('\n')

c1=0
for seed in seeds:
    c1+=1
    print(f"  Extracting data ({c1} of {len(seeds)})      ", end="\r")
    st = obspy.read(seed)
    
    if detrend_type == 'spline':
        st.detrend(detrend_type, order=2, dspline=merge_event_threshold/100)
    else:
        st.detrend(detrend_type)
    
    st.taper(taper_max_percentage)

    st.sort(['starttime'])
    trace=[]; station=[]; channel=[]; stacha=[]; length=[]; event=[]; time=[];
    for i in range(len(st)):
        if wcard([st[i].stats.channel], channels):
            trace.append(st[i])
            station.append(st[i].stats.station)
            channel.append(st[i].stats.channel)
            stacha.append(st[i].stats.station+'.'+st[i].stats.channel)
            length.append(round(st[i].stats.npts*st[i].stats.delta,0))
            yy  = str(st[i].stats.starttime.year)[2:]
            jjj = '%03d' %(st[i].stats.starttime.julday)
            hh  = '%02d' %(st[i].stats.starttime.hour)
            mm  = '%02d' %(st[i].stats.starttime.minute)
            ss  = '%02d' %(st[i].stats.starttime.second)
            event.append(yy+jjj+hh+mm+ss)
            time.append(st[i].stats.starttime.timestamp)
    
    max_length=np.max(length)
    if merge_event_threshold != 'auto':
        max_length = merge_event_threshold

    #stacha members are strings in "station.channel" format
    stacha_index_group=[]
    for i in range(len(stacha)):
        if find_duplicates(stacha,stacha[i]) not in stacha_index_group:
            stacha_index_group.append(find_duplicates(stacha,stacha[i]))

    for i in range(len(stacha_index_group)):
        if len(stacha_index_group[i]) == 1: # no merging is required!
            fname = event[stacha_index_group[i][0]]+'_'+stacha[stacha_index_group[i][0]]
            fname0 = fname
            fname=os.path.join(outdir,fname)
            st2=trace[stacha_index_group[i][0]].copy()
            
            st2.write(fname,format='SAC')
            if make_event_dirs == 'yes':
                        dirname = os.path.join(outdir, event[stacha_index_group[i][0]])
                        if os.path.isdir(dirname):
                            pass
                        else:
                            os.makedirs(dirname)
                
                        for item in glob.glob(os.path.join(dirname,fname0)+'*'):
                            os.remove(item)
                            
                        for item in glob.glob(os.path.join(outdir,fname0)+'*'):
                            shutil.move(item, dirname)
                    

        else: #check if merging is required
            dtime=[]
            dtime_index=[]
            ref=stacha_index_group[i][0]
            k=0
            
            while k < len(stacha_index_group[i]):
                current_index=stacha_index_group[i][k]
                dtime.append(round(abs(time[current_index] - time[ref]),0))
                dtime_index.append(current_index)
                

                if dtime[-1] > max_length:
                    k=k-1
                    fname=event[dtime_index[0]]+'_'+stacha[dtime_index[0]]
                    fname0 = fname
                    fname=os.path.join(outdir,fname)

                    ii=0
                    temp=[os.path.join(outdir,'temp0')]
                    trace[dtime_index[0]].write(temp[-1], format='SAC')
                    st2=obspy.read(temp[-1])
                    while ii < len(dtime)-2:
                        ii+=1
                        temp.append(os.path.join(outdir,'temp'+str(ii)))
                        trace[dtime_index[ii]].write(temp[-1], format='SAC')
                        st2+=obspy.read(temp[-1])
                    
                    if output_fragmented == 'yes':
                        c=1
                        for tmp in temp:
                            shutil.copyfile(tmp, fname+'.p'+str('%02d' %(c)))
                            c+=1
                            
                    for tmp in temp:
                        os.remove(tmp)

                    st2.sort(['starttime'])
                    st2.merge(method=1, fill_value=fill_gap_value)
            
                    st2.write(fname, format='SAC')
                    
                    if make_event_dirs == 'yes':
                        dirname = os.path.join(outdir, event[dtime_index[0]])
                        if os.path.isdir(dirname):
                            pass
                        else:
                            os.makedirs(dirname)
                
                        for item in glob.glob(os.path.join(dirname,fname0)+'*'):
                            os.remove(item)
                            
                        for item in glob.glob(os.path.join(outdir,fname0)+'*'):
                            shutil.move(item, dirname)

                    ref=current_index
                    dtime=[]
                    dtime_index=[]

                elif current_index == stacha_index_group[i][-1]:
                    fname=event[dtime_index[0]]+'_'+stacha[dtime_index[0]]
                    fname0 = fname
                    fname=os.path.join(outdir,fname)

                    ii=0
                    temp=[os.path.join(outdir,'temp0')]
                    trace[dtime_index[0]].write(temp[-1], format='SAC')
                    st2=obspy.read(temp[-1])
                    while ii < len(dtime)-1:
                        ii+=1
                        temp.append(os.path.join(outdir,'temp'+str(ii)))
                        trace[dtime_index[ii]].write(temp[-1], format='SAC')
                        st2+=obspy.read(temp[-1])
                    
                    if output_fragmented == 'yes':
                        c=1
                        for tmp in temp:
                            shutil.copyfile(tmp, fname+'.p'+str('%02d' %(c)))
                            c+=1
                            
                    for tmp in temp:
                        os.remove(tmp)
                        
                    st2.merge(method=1, fill_value=fill_gap_value)
                    
                    st2.write(fname, format='SAC')
                    
                    if make_event_dirs == 'yes':
                        dirname = os.path.join(outdir, event[dtime_index[0]])
                        if os.path.isdir(dirname):
                            pass
                        else:
                            os.makedirs(dirname)
                
                        for item in glob.glob(os.path.join(dirname,fname0)+'*'):
                            os.remove(item)
                            
                        for item in glob.glob(os.path.join(outdir,fname0)+'*'):
                            shutil.move(item, dirname)
                        
                k=k+1

#Merge event directories
if make_event_dirs == 'yes' and merge_event_threshold != 'auto':
    event_dir = wcard(os.listdir(outdir), '[0-1][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
    event_dir.sort()
    
    event_time=[]
    for event in event_dir:
        t = f"20{event[0:2]}-{event[2:5]}T{event[5:7]}:{event[7:9]}:{event[9:11]}"
        t=obspy.UTCDateTime(t)
        event_time.append(t)
    
    event_groups=[]
    i=0
    while i < len(event_time):
        t0 = event_time[i]
        temp=[]
        j=0
        while j < len(event_time):
            dt=event_time[j]-t0
            if dt < merge_event_threshold and dt >= 0:
                temp.append(j)
            j+=1
    
        event_groups.append(temp)
        i+=1
    
    temp=[0]
    event_groups_merge_index=[]
    i=0
    while i < len(event_groups):
        if len(event_groups[i]) > temp[-1] and len(event_groups[i]) > 1:
            temp.insert(i,event_groups[i][0])
            event_groups_merge_index.append(event_groups[i])
        else:
            temp=[0]
    
        i+=1
    
    if len(event_groups_merge_index) != 0:
        uans=input("\n\nDo you want to merge interfered event directories (y/n)? ")
        if uans != 'y':
            print('\n\nDone!\n')
            exit()
    
    
    #begin merging event folders:
    for group in event_groups_merge_index:
        dest_dir=os.path.join(outdir,event_dir[group[0]])
        j=1
        while j < len(group):
            source_dir=os.path.join(outdir,event_dir[group[j]])
            files=os.listdir(source_dir)
            for item in files:
                file=os.path.join(source_dir,item)
                if os.path.isfile(os.path.join(dest_dir,item)):
                    os.remove(os.path.join(dest_dir,item))

                shutil.move(file,dest_dir)

    
            shutil.rmtree(source_dir)
            j+=1


print('\n\nDone!\n')

