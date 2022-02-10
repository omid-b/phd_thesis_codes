#!/usr/bin/env python3

about = "This script carries out the gradient damping tests for Sergei Lebedev's tomography code\n"

usage = '''
Usage:
  python gradtest.py  inbac  iniac  inxc  outputdir
'''
# Note: one can input 'inbac_outl' instead of 'inbac' file (recommended)

# CODED BY: omid.bagherpur@gmail.com
# UPDATE: 11 Sep 2020
#======Adjustable Parameters======#
bac_compiled = "/data/home/omid_b/Ambient-Noise-Tomography/tomography/BIN/bac"
iac_compiled = "/data/home/omid_b/Ambient-Noise-Tomography/tomography/BIN/iac"
xsc_compiled = "/data/home/omid_b/Ambient-Noise-Tomography/tomography/BIN/xsc"

period = 16

grad_values = [0.00001, 0.00004, 0.00008, 0.0001, 0.0005,\
               0.0010, 0.0050, 0.0100, 0.0330, 0.0660, 0.1000,\
               0.1330, 0.1660, 0.2000, 0.2330, 0.2660, 0.3000,\
               0.3330, 0.3660, 0.4000, 0.4500, 0.5000, 0.6000,\
               0.7000, 0.8000, 0.9000, 1.0000, 1.5000, 2.0000,\
               2.5000, 3.0000]

# Notes: 1) all other parameters are fixed and read from the inputs
#           e.g., "smoothing values" and "norm damping values" 
#        2) when running damp tests for isotropic component, damping
#           parameters for the anisotropic are fixed (read from 'iniac');
#           similar logic is applied when running damp tests for the 
#           anisotropic components
#=================================#
import os 
import sys
os.system('clear')
print(about)

try:
    import subprocess
    from glob import glob
    from shutil import rmtree
    from shutil import copyfile
    from numpy import array
except ImportError as e:
    print(f'\n{e}\n')

if (len(sys.argv) != 5):
    print(f"Error Usage!\n\n{usage}\n")
    exit()

if not os.path.isfile(bac_compiled):
    print(f"Error!\n Could not find 'bac_compiled'; check 'Adjustable Parameters'.\n")
    exit()

if not os.path.isfile(iac_compiled):
    print(f"Error!\n Could not find 'iac_compiled'; check 'Adjustable Parameters'.\n")
    exit()

if not os.path.isfile(xsc_compiled):
    print(f"Error!\n Could not find 'xsc_compiled'; check 'Adjustable Parameters'.\n")
    exit()


if not os.path.isfile(sys.argv[1]):
    print(f"Error! could not find 'inbac'.\n\n{usage}")
    exit()
else:
    try:
        inbac = open(sys.argv[1], 'r').read().splitlines()
        datalist = inbac[0]
        periods = []
        refvels = {}
        outliers = {}
        for line in inbac[2:int(inbac[1])+2]:
            periods.append(int(line.split()[0]))
            refvels[f'{periods[-1]}'] = float(line.split()[1])
            if len(line.split()) > 2:
                outliers[f'{periods[-1]}'] = line.split()[2]

        pathWidth = inbac[int(inbac[1])+3]
        grdSpacing = array(inbac[int(inbac[1])+4].split(), dtype=float)
    except:
        print(f"Error in reading 'inbac' file!\n{usage}\n")
        exit()

if not os.path.isfile(sys.argv[2]):
    print(f"Error! could not find 'iniac'.\n\n{usage}")
    exit()
else:
    try:
        iniac = open(sys.argv[2], 'r').read().splitlines()
        max_iter = int(iniac[0])
        int_sol = int(iniac[1])
        iters = ' '.join(iniac[2].split())
        dmp = ' '.join(iniac[3].split())
        smth = ' '.join(iniac[4].split())
        grad_dmp = ' '.join(iniac[5].split())
    except:
        print(f"Error in reading 'iniac' file!\n{usage}\n")
        exit()

if not os.path.isfile(sys.argv[3]):
    print(f"Error! could not find 'inxc'.\n\n{usage}")
    exit()
else:
    try:
        inxc = open(sys.argv[3], 'r').read().splitlines()
        plt_colsum_flag = int(inxc[0])
        xsc_smth_flag = int(inxc[1])
        xsc_scale_limit = array(inxc[2].split(), dtype=float)
        xsc_interp_output_flag = int(inxc[3].split()[0])
        xsc_interp_output_value = float(inxc[3].split()[1])
        xsc_region_only_flag = int(inxc[4].split()[0])
        xsc_region_only_value = float(inxc[4].split()[1])
    except:
        print(f"Error in reading 'inxc' file!\n{usage}\n")
        exit()

if period not in periods:
            print(f"Error! The given period, {period} s, is not in the list of periods!\n\n")
            exit()

outputdir = os.path.abspath(sys.argv[4])

report = f'\n\n Period: {period} s\n #gradient damping values: {len(grad_values)}\n gradient damping values (min, max):  {min(grad_values)}  {max(grad_values)}\n output directory: {outputdir}\n\n'

print(report)

if os.path.isdir(sys.argv[4]):
    print(f"\n!!!WARNING!!!\nThe output directory already exists!\nThis script will remove and remake the output directory.")

uin = input('Do you want to continue (y/n)? ')

if not uin.lower() == 'y':
    print('\n\nExit program!\n\n')
    exit()

if os.path.isdir(outputdir):
    rmtree(outputdir)
    os.mkdir(outputdir)
    os.mkdir(os.path.join(outputdir,'gradtest_isotropic'))
    os.mkdir(os.path.join(outputdir,'gradtest_anisotropic'))
else:
    os.mkdir(outputdir)
    os.mkdir(os.path.join(outputdir,'gradtest_isotropic'))
    os.mkdir(os.path.join(outputdir,'gradtest_anisotropic'))

#---FUNCTIONS---#

def write_inbac(inbacdir):
    fn = open(os.path.join(inbacdir,'inbac'), 'w')
    inbac_txt = [datalist, '1', f'{period} {refvels[f"{period}"]}', '2', f'{pathWidth}', f'{grdSpacing[0]} {grdSpacing[1]}']
    if f'{period}' in outliers:
        inbac_txt[2] = f'{period} {refvels[f"{period}"]} {outliers[f"{period}"]}'
    fn.write('\n'.join(inbac_txt))
    fn.close()

def write_iniac(iniacdir, grad_dmp):
    fn = open(os.path.join(iniacdir,'iniac'), 'w')
    iniac_txt = [f'{max_iter}', f'{int_sol}', iters, dmp, smth, f'{grad_dmp[0]} {grad_dmp[1]} {grad_dmp[2]}', '0 0 0', '0 0 0']
    fn.write('\n'.join(iniac_txt))
    fn.close()

def write_inxc(inxcdir):
    copyfile(sys.argv[3], os.path.join(inxcdir, 'inxc'))

def run_inversions(invdir):
    shell_cmd = '\n'.join([f'cd {invdir}', f'{bac_compiled} < inbac > outbac'])
    subprocess.call(shell_cmd, shell=True) #run bac
    for f in glob(f'{invdir}/*{period}'):
        os.rename(f, f[0:-3])
    shell_cmd = '\n'.join([f'cd {invdir}', f'{iac_compiled} < iniac > outiac', f'{xsc_compiled} < inxc > outxc'])
    subprocess.call(shell_cmd, shell=True) #run iac and xsc
    shell_cmd = '\n'.join([f'cd {invdir}', 'grep ^"[nlig ][oatr 0-9][rtea 0-9][merd0-9]" outiac > tmp', "tail -1 tmp | awk '{print $7}' > tradeoff", "grep roughness outiac|awk '{print $3}' >> tradeoff", 'rm -f tmp'])
    subprocess.call(shell_cmd, shell=True)

#--------------#


# ---MAIN PROCESS--- #

# STEP1: initialize inversion directories
invdirs = []
for val in grad_values:
    # isotropic tests
    invdirs.append(os.path.join(outputdir,'gradtest_isotropic','%08.5f-%08.5f-%08.5f' %(val, float(grad_dmp.split()[1]), float(grad_dmp.split()[2]))))
    os.mkdir(invdirs[-1])
    write_inbac(invdirs[-1])
    write_iniac(invdirs[-1], [val, grad_dmp.split()[1], grad_dmp.split()[2]])
    write_inxc(invdirs[-1])

    # anisotropic tests
    invdirs.append(os.path.join(outputdir,'gradtest_anisotropic','%08.5f-%08.5f-%08.5f' %(float(grad_dmp.split()[0]), val, val)))
    os.mkdir(invdirs[-1])
    write_inbac(invdirs[-1])
    write_iniac(invdirs[-1], [grad_dmp.split()[0], val, val])
    write_inxc(invdirs[-1])

copyfile(sys.argv[1], os.path.join(outputdir, 'inbac'))
copyfile(sys.argv[2], os.path.join(outputdir, 'iniac'))
copyfile(sys.argv[3], os.path.join(outputdir, 'inxc'))
    
print('\n > Inversion directories generated.')

# STEP2: run inversions
i = 0
for invdir in invdirs:
    i += 1
    print(f' > Running inversions ({i} of {len(invdirs)}): {os.path.basename(invdir)}')
    run_inversions(invdir)


print(f'\n\nGradient damping test is completed!\n\n')

