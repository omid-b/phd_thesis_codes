#!/usr/bin/env python3
# An interactive plot will be generated to make the design easy!
import os
import sys
about = "This script automates the design process of the spike resolution tests for Sergei's tomography code.\n"
usage = f'''
 USAGE:
 > python3 {sys.argv[0]} [inversion_results_dir]
'''
# CODED BY: omid.bagherpur@gmail.com
# UPDATE: 25 Jan 2021
#===================================#
max_num_saves = 6

# plot parameters
marker_size = 50
on_color = (0.85, 0.117, 0.215) # (R,G,B)
off_color = (0, 0.5, 0.65) # (R,G,B)
map_margin_factor = [0.1, 0.2, 0.2, 0.1] # top, right, bottom, left
#===================================#
# Code Block!

os.system('clear')
print(about)

try:
    import io
    import re
    import shutil
    import numpy as np
    from PIL import Image
    from math import pi
    import matplotlib as mpl
    import matplotlib.pyplot as plt
    from mpl_toolkits.basemap import Basemap
    from matplotlib.widgets import RectangleSelector
except ImportError as ie:
    print(ie)
    exit()

if len(sys.argv) != 2:
    print(f"\nError usage!\n{usage}\n")
    exit()
else:
    invdir = os.path.abspath(sys.argv[1])

if not os.path.isdir(invdir):
    print("\nError! Could not find the given inversion results directory!\n")
    exit()

# find the list of periods
periods = []
for x in os.listdir(invdir):
    if re.search("^[0-9][0-9][0-9]$", x):
        periods.append(x)
periods = sorted(periods)
nprd = len(periods)

if nprd == 0:
    print('Error! Could not find period directories in the given directory!\n')
    exit()

# check if all "shell" files are available and then read their lines
points_prd = dict()
for iprd in range(nprd):
    if not 'shell' in os.listdir(os.path.join(invdir, periods[iprd])):
        print(f"Error! Could not find the file 'shell' for the period directory {periods[iprd]}\n")
        exit()
    else:
        with open(os.path.join(invdir,periods[iprd],'shell')) as f:
            lines = f.readlines()
            lat = np.around(np.array(lines[1].split(), dtype=float)*180/pi, 4)
            lon = np.around(np.array(lines[2].split(), dtype=float)*180/pi, 4)
            for k in range(len(lon)):
                if lon[k] > 180:
                    lon[k] -= 360
            points_prd[f'{periods[iprd]}'] = list(zip(lon, lat))

points = [] # a unique list of all points
for iprd in range(nprd):
    for point in points_prd[periods[iprd]]:
        point = (point[0], point[1])
        if point not in points:
            points.append(point)
points = sorted(points)
points = np.array(points, dtype=float)

# write report
report = f"  Inversion results dir: %s\n  Number of periods: %d\n  Period range: %.0f-%.0f s\n  Number of nodes: %d\n" \
%(invdir, nprd, np.min(np.array(periods, dtype=float)), np.max(np.array(periods, dtype=float)), len(points))
print(report)

print("  Generating the interactive map ...", end="  \r")

#----FUNCTIONS----#
def gen_color_array(switched_on):
    colors = x = [[]] * len(switched_on)
    for i in range(len(switched_on)):
        if switched_on[i]:
            colors[i] = on_color
        else:
            colors[i] = off_color
    return colors


def on_pick(event):
    if event.mouseevent.button==1:
        ind = event.ind[0]
        switched_on[ind] = True
        mplcoll.set_facecolor(gen_color_array(switched_on))
        mplcoll.set_edgecolor(gen_color_array(switched_on))
        fig.canvas.draw()
    elif event.mouseevent.button==3:
        ind = event.ind[0]
        switched_on[ind] = False
        mplcoll.set_facecolor(gen_color_array(switched_on))
        mplcoll.set_edgecolor(gen_color_array(switched_on))
        fig.canvas.draw()


def on_press(event):
    global switched_on, cellsize, saved_models, buf
    # finish design
    if event.key in ['f', 'F']:
        print(f"  Number of saved models: {len(saved_models)}\n")
        plt.close()
    # quit program
    if event.key in ['q', 'Q', 'escape']:
        plt.close()
        print("  Number of saved models: 0\n")
        print('\nQuit program!\n')
        for i in range(len(fig_buffers)):
            fig_buffers[i].close()
            exit()
    # reset
    if event.key in ['r', 'R']:
        cellsize = 0
        switched_on = np.zeros(len(points), dtype=bool)
        draw_canvas(switched_on)
    # invert
    if event.key in ['i', 'I']:
        switched_on = [not x for x in switched_on]
        draw_canvas(switched_on)
    if event.key in ['s', 'S', 'enter']:
        saved_models.append(switched_on)
        fig_buffers.append(io.BytesIO())
        plt.savefig(fig_buffers[-1], format='png')
        print("  Number of saved models: %d" %(len(saved_models)), end="    \r")
        if len(saved_models) == max_num_saves:
            print(f"  Number of saved models: {max_num_saves}\n")
            plt.close()




def draw_canvas(switched_on):
    global colors
    colors = gen_color_array(switched_on)
    mplcoll.set_facecolor(colors)
    mplcoll.set_edgecolor(colors)
    fig.canvas.draw()



def box_select_lmb_callback(eclick, erelease):
    global switched_on
    x1, y1 = map(eclick.xdata, eclick.ydata, inverse=True)
    x2, y2 = map(erelease.xdata, erelease.ydata, inverse=True)
    xRange = [min(x1,x2), max(x1,x2)]
    yRange = [min(y1,y2), max(y1,y2)]
    for ip in range(len(points)):
        px = points[ip, 0]
        py = points[ip, 1]
        if xRange[0] <= px <= xRange[1] and yRange[0] <= py <= yRange[1]:
            switched_on[ip] = True
    draw_canvas(switched_on)


def box_select_rmb_callback(eclick, erelease):
    global switched_on
    x1, y1 = map(eclick.xdata, eclick.ydata, inverse=True)
    x2, y2 = map(erelease.xdata, erelease.ydata, inverse=True)
    xRange = [min(x1,x2), max(x1,x2)]
    yRange = [min(y1,y2), max(y1,y2)]
    for ip in range(len(points)):
        px = points[ip, 0]
        py = points[ip, 1]
        if xRange[0] <= px <= xRange[1] and yRange[0] <= py <= yRange[1]:
            switched_on[ip] = False

    draw_canvas(switched_on)

def box_select_lmb(event):
    pass

def box_select_rmb(event):
    pass

def format_coord(x, y):
    return 'Lon= %.2f   Lat= %.2f  '%(map(x, y, inverse = True))

#-----------------#

cellsize = 0
switched_on = np.zeros(len(points), dtype=bool)
colors = gen_color_array(switched_on)

mpl.rcParams['toolbar'] = 'toolbar2' # 'None' for disabling the toolbar
fig = plt.figure()
ax = fig.add_subplot(111)
ax.format_coord = format_coord

# map region
lonRangeSize = np.max(points[:,0]) - np.min(points[:,0])
latRangeSize = np.max(points[:,1]) - np.min(points[:,1])
urcrnrlat = np.max(points[:,1]) + latRangeSize * map_margin_factor[0]
urcrnrlon = np.max(points[:,0]) + lonRangeSize * map_margin_factor[1]
llcrnrlat = np.min(points[:,1]) - latRangeSize * map_margin_factor[2]
llcrnrlon = np.min(points[:,0]) - lonRangeSize * map_margin_factor[3]
lat_1 = np.min(points[:,1])
lat_2 = np.max(points[:,1])
lon_0 = np.mean(points[:,0])
lat_0 = np.mean(points[:,1])

map = Basemap(llcrnrlon=llcrnrlon,llcrnrlat=llcrnrlat,
          urcrnrlon=urcrnrlon,urcrnrlat=urcrnrlat,
            projection='lcc',lat_1=lat_1,lat_2=lat_2,
            lon_0=lon_0,lat_0=lat_0, resolution ='i',
            area_thresh=1000., ax=ax)

map.fillcontinents(color=(0,0,0,0.1), zorder=-1)
map.drawcountries(linewidth=0.4)
map.drawcoastlines(linewidth=0.25)

x, y = map(points[:,0], points[:,1])

mplcoll = map.scatter(x, y, color=colors, zorder=10,
                     picker = [1]*len(points),
                     s=[marker_size]*len(points))


box_select_lmb.RS = RectangleSelector(ax,
                                  box_select_lmb_callback,
                                  drawtype='box',
                                  useblit=True,
                                  button=1, 
                                  minspanx=1,
                                  minspany=1,
                                  spancoords='pixels',
                                  rectprops=dict(facecolor='gray',alpha=0.3, edgecolor='black'))

box_select_rmb.RS = RectangleSelector(ax,
                                  box_select_rmb_callback,
                                  drawtype='box',
                                  useblit=True,
                                  button=3, 
                                  minspanx=1,
                                  minspany=1,
                                  spancoords='pixels',
                                  rectprops=dict(facecolor='gray',alpha=0.3, edgecolor='black'))

fig.canvas.mpl_connect('pick_event', on_pick)
fig.canvas.mpl_connect('key_press_event', on_press)
fig.canvas.mpl_connect('key_press_event', box_select_lmb)
fig.canvas.mpl_connect('key_press_event', box_select_rmb)


print("  Generating the interactive map ... Done!\n")


hint = f'''
  LMB click/drag: switch on
  RMB click/drag: switch off
  r: reset all (switch all nodes to off)
  i: invert design
  s/enter: save current design (up to {max_num_saves})
  f: finish design
  q/escape: quit program (disregard saves)
  
  *LMB: left mouse button
  *RMB: right mouse button

'''


print(hint)


fig_buffers = []
saved_models = []

print("  Number of saved models: %d" %(len(saved_models)), end="    \r")

plt.rcParams['keymap.save'].remove('s')
plt.show()


if len(saved_models) == 0:
    print("\n  Error: no model has been saved!\n\n  Exit program!\n\n")
    exit()
else:
    # remove existing output files
    spiketest_dir = os.path.join(invdir,'spiketest_models')
    if os.path.isdir(spiketest_dir):
        shutil.rmtree(spiketest_dir)
    for prd in periods:
        for x in os.listdir(os.path.join(invdir, prd)):
            if re.search("^(spk)", x):
                os.remove(os.path.join(invdir,prd,x))

    # start writting outputs
    for imod in range(len(saved_models)):
        for prd in periods:
            print(f"  Writing outputs for model {imod+1} of {len(saved_models)}; Period: {prd}", end="   \r")
            spk_file = os.path.join(invdir, prd, f"spk{imod+1}")
            spk_pdf = os.path.join(invdir, prd, f"spk{imod+1}.pdf")
            prd_modl = []
            for ipp in range(len(points_prd[prd])):
                for ip in range(len(points)):
                    if points[ip][0] == points_prd[prd][ipp][0] and points[ip][1] == points_prd[prd][ipp][1]:
                        if saved_models[imod][ip]:
                            prd_modl.append(ipp)
            # save figures: "spk?.pdf"
            switched_on = np.zeros(len(points_prd[prd]), dtype=bool)
            for k in prd_modl:
                switched_on[k] = True
            colors = gen_color_array(switched_on)
            fig = plt.figure()
            ax = fig.add_subplot(111)
            map = Basemap(llcrnrlon=llcrnrlon,llcrnrlat=llcrnrlat,
                      urcrnrlon=urcrnrlon,urcrnrlat=urcrnrlat,
                        projection='lcc',lat_1=lat_1,lat_2=lat_2,
                        lon_0=lon_0,lat_0=lat_0, resolution ='i',
                        area_thresh=1000., ax=ax)
            map.fillcontinents(color=(0,0,0,0.1), zorder=-1)
            map.drawcountries(linewidth=0.4)
            map.drawcoastlines(linewidth=0.25)
            xy = np.array(points_prd[prd])
            x, y = map(xy[:,0], xy[:,1])
            mplcoll = map.scatter(x, y, color=colors, zorder=10,
                                 picker = [1]*len(xy),
                                 s=[marker_size]*len(xy))
            plt.savefig(fname=spk_pdf, format='pdf')
            plt.close()
            # write "spk?" file
            with open(spk_file,'w') as spk:
                spk.write(f"number of nodes\n")
                spk.write(f"{len(prd_modl)}\n")
                spk.write(f"which nodes\n")
                for ndindx in prd_modl:
                    spk.write(f"{ndindx+1}\n")
        print(f"\n")


# write saved models figures (all uniq points)
os.mkdir(spiketest_dir)
for i in range(len(fig_buffers)):
    im = Image.open(fig_buffers[i])
    im.save(os.path.join(spiketest_dir,f'spk{i+1}.png'))
    fig_buffers[i].close()
    with open(os.path.join(spiketest_dir,f'spk{i+1}.dat'), 'w') as f:
        for k in range(len(saved_models[i])):
            if saved_models[i][k]:
                f.write("%.2f %.2f 1\n" %(points[k,0], points[k,1]))
            else:
                f.write("%.2f %.2f 0\n" %(points[k,0], points[k,1]))


print(f'\n  Done!\n')

