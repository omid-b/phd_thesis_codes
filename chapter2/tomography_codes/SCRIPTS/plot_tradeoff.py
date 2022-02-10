#!/usr/bin/env python3

about = "This script generates plots of tradeoff curves for the results of regularization parameters tests.\n"

usage = '''
Usage:
  python plot_tradeoff.py  regTestDir
'''
# Note: this script can be used to generate plots for the results
# of the following scripts: 1) smoothtest.py 2) damptest.py
#                           3) gradtest.py

# CODED BY: omid.bagherpur@gmail.com
# UPDATE: 13 Sep 2020
#======Adjustable Parameters======#
#Figure style:
output_filetype = 'pdf'
depthTick= 20
vsTick   = 0.25
legSize  = 12 #legend font size
figSize  = (6,6) # Size of the figure along (x, y) axis
context  = "notebook" ;# seaborn set_context: notebook, talk, poster, paper
style    = "ticks" ; # seaborn styles: darkgrid, whitegrid, white, ticks ...

# [[index1, x-offset1, y-offset1], [index2, x-offset2, y-offset2], ...]
textinfo_isotropic = [[9,0,0]] 
textinfo_2psi = [[0,0,0], [41,0,0], [19,0,0]]
textinfo_4psi = [[0,0,0], [41,0,0], [19,0,0]]

# for damp test
textinfo_isotropic = [[0,0,-0.001],[9,-1,0.001],[18,0,0],[23,0,0],[32,0,0]] 
textinfo_2psi = [[0,0,-0.001],[10,-1,0.001],[18,0,0],[25,0,0],[32,0,0]] 
textinfo_4psi = [[0,0,-0.001],[10,-1,0.001],[18,0,0],[25,0,0],[32,0,0]] 


# for smooth test
textinfo_isotropic = [[0,0,-0.001],[14,-1,0.001],[22,0,0],[30,0,0],[36,0,0]] 
textinfo_2psi = [[0,0,-0.001],[14,-1,0.001],[24,0,0],[30,0,0],[36,0,0]] 
textinfo_4psi = [[0,0,-0.001],[14,-1,0.001],[24,0,0],[30,0,0],[36,0,0]] 
#=================================#
import os 
import sys
os.system('clear')
print(about)

try:
    import seaborn as sns
    import matplotlib.pyplot as plt
    from glob import glob
    from numpy import array
    from numpy import float
except ImportError as e:
    print(f'\n{e}\n')

if (len(sys.argv) != 2):
    print(f"Error Usage!\n\n{usage}\n")
    exit()

if not os.path.isdir(sys.argv[1]):
    print(f"Error! could not find 'regTestDir'.\n\n{usage}")
    exit()

anisdir = glob(f'{os.path.abspath(sys.argv[1])}/*_anisotropic')
isodir = glob(f'{os.path.abspath(sys.argv[1])}/*_isotropic')
if len(anisdir) != 1 or len(anisdir) != 1:
    print(f'Error! "regTestDir" should contain "*_isotropic" and "_anisotropic" directories.\n{usage}')
    exit()
else:
    anisdir = anisdir[0]
    isodir = isodir[0]

testType = os.path.basename(isodir).split('_')[0]
if testType == 'smoothtest':
    regularization_type = "Smoothing"
elif testType == 'damptest':
    regularization_type = "Norm damping"
elif testType == 'gradtest':
    regularization_type = "Gradient damping"
else:
    regularization_type = "Regularization"


anistest = sorted(glob(f'{anisdir}/*-*-*'))
isotest = sorted(glob(f'{isodir}/*-*-*'))

print(f'  {regularization_type} test dir: {os.path.abspath(sys.argv[1])}\n  #{regularization_type} values: {len(isotest)}\n')

uin = input('Do you want to continue (y/n)? ')

if not uin.lower() == 'y':
    print('\n\nExit program!\n\n')
    exit()


anis_keys = []
iso_keys = []
anis_tradeoff = {}
iso_tradeoff = {}
anis_text = {}
iso_text = {}
for i in range(len(anistest)):

    if not os.path.isfile(os.path.join(anisdir,anistest[i],'tradeoff')):
        print(f'Error! Could not find "tradoff" in "{anistest[i]}"!\n\n')
        exit()
    else:
        f1 = open(os.path.join(anisdir,anistest[i],'tradeoff'), 'r')
        key = os.path.basename(anistest[i])
        anis_keys.append(key)
        anis_tradeoff[key] = array(f1.read().splitlines(), dtype=float)
        anis_text[key] = f"{float(key.split('-')[1])}"
        f1.close()

    if not os.path.isfile(os.path.join(isodir,isotest[i],'tradeoff')):
        print(f'Error! Could not find "tradoff" in "{isotest[i]}"!\n\n')
        exit()
    else:
        f2 = open(os.path.join(isodir,isotest[i],'tradeoff'), 'r')
        key = os.path.basename(isotest[i])
        iso_keys.append(key)
        iso_tradeoff[key] = array(f2.read().splitlines(), dtype=float)
        iso_text[key] = f"{float(key.split('-')[0])}"
        f2.close()

print('\n  Generating plots ...\n')

#---FUNCTIONS---#

def gen_plot(x,y, xlabel, legend, xyText, output):
    sns.set(style=style)
    sns.set_context(context)
    plt.figure(1,figSize)
    plt.plot(x, y,label=legend, zorder=2, color='gray')
    plt.scatter(x, y,color='gray', marker='o', zorder=2, s=3)
    for text in xyText:
        plt.text(text[0]+text[2],text[1]+text[3],text[4], fontdict=None)
        plt.scatter(text[0],text[1],color='black', zorder=3, marker='o', s=16)

    plt.xlabel(xlabel)
    plt.ylabel('Remaining variance')
    plt.legend(loc='best', prop={'size':legSize})
    plt.tight_layout()
    plt.savefig(output,dpi=300,transparent=True)
    plt.close()

def gen_combiend_plot(x1,y1, xyText1, x2, y2, xyText2, x3,y3, xyText3, output):
    sns.set(style=style)
    sns.set_context(context)
    plt.figure(1,figSize)
    plt.title(f'{regularization_type} trade-off curves')
    plt.plot(x1, y1,label=f'Isotropic', zorder=2, color='gray')
    plt.scatter(x1, y1,color='gray', marker='o', zorder=2, s=3)
    for text in xyText1:
        # plt.text(text[0]+text[2],text[1]+text[3],text[4], color='k')
        plt.scatter(text[0],text[1], zorder=3, marker='o', s=16, color='k')
    plt.plot(x2, y2, linestyle='--',label=f'2-psi', zorder=2, color='gray')
    plt.scatter(x2, y2,color='gray', marker='o', zorder=2, s=3)
    for text in xyText2:
        # plt.text(text[0]+text[2],text[1]+text[3],text[4], color='k')
        plt.scatter(text[0],text[1], zorder=3, marker='o', s=16, color='k')
    plt.plot(x3, y3,linestyle=':',label=f'4-psi', zorder=2, color='gray')
    plt.scatter(x3, y3,color='gray', marker='o', zorder=2, s=3)
    for text in xyText3:
        # plt.text(text[0]+text[2],text[1]+text[3],text[4], color='k')
        plt.scatter(text[0],text[1], zorder=3, marker='o', s=16, color='k')

    plt.xlabel('Roughness')
    plt.ylabel('Remaining variance')
    plt.legend(loc='best', prop={'size':legSize})
    plt.tight_layout()
    plt.savefig(output,dpi=300,transparent=True)
    plt.close()

#---------------#

anis_remVar = []
roughness_2psi = []
roughness_4psi = []
for i in range(len(anis_keys)):
    anis_remVar.append(anis_tradeoff[anis_keys[i]][0])
    roughness_2psi.append(anis_tradeoff[anis_keys[i]][2])
    roughness_4psi.append(anis_tradeoff[anis_keys[i]][3])

iso_remVar = []
roughness_c = []
for i in range(len(iso_keys)):
    iso_remVar.append(iso_tradeoff[iso_keys[i]][0])
    roughness_c.append(iso_tradeoff[iso_keys[i]][1])

text_isotropic = []
for i in range(len(textinfo_isotropic)):
    if textinfo_isotropic[i][0] < len(iso_keys):
        key = iso_keys[textinfo_isotropic[i][0]]
        x = iso_tradeoff[key][1]
        y = iso_tradeoff[key][0]
        text = iso_text[key]
        text_isotropic.append([x, y, textinfo_isotropic[i][1], textinfo_isotropic[i][2], text])

text_2psi = []
for i in range(len(textinfo_2psi)):
    if textinfo_2psi[i][0] < len(anis_keys):
        key = anis_keys[textinfo_2psi[i][0]]
        x = anis_tradeoff[key][2]
        y = anis_tradeoff[key][0]
        text = anis_text[key]
        text_2psi.append([x, y, textinfo_2psi[i][1], textinfo_2psi[i][2], text])

text_4psi = []
for i in range(len(textinfo_4psi)):
    if textinfo_4psi[i][0] < len(anis_keys):
        key = anis_keys[textinfo_4psi[i][0]]
        x = anis_tradeoff[key][3]
        y = anis_tradeoff[key][0]
        text = anis_text[key]
        text_4psi.append([x, y, textinfo_4psi[i][1], textinfo_4psi[i][2], text])


gen_plot(roughness_c,iso_remVar,'Isotropic roughness',\
    f'{regularization_type} trade-off (Isotropic)', text_isotropic,\
    os.path.join(sys.argv[1],'isotropic-tradeoff.pdf'))
gen_plot(roughness_2psi,anis_remVar,'Anisotropic roughness',\
    f'{regularization_type} trade-off (2-psi)', text_2psi,\
    os.path.join(sys.argv[1],'2psi-tradeoff.pdf'))
gen_plot(roughness_4psi,anis_remVar,'Anisotropic roughness',\
    f'{regularization_type} trade-off (4-psi)', text_4psi,\
    os.path.join(sys.argv[1],'4psi-tradeoff.pdf'))

gen_combiend_plot(roughness_c,iso_remVar, text_isotropic,roughness_2psi,\
    anis_remVar,text_2psi,roughness_4psi,anis_remVar,text_4psi,\
    os.path.join(sys.argv[1],'all-tradeoff.pdf'))

print(f'Plots generated in the smoothing test dir.\n\n')

