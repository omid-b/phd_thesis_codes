#!/bin/csh
# Adjustable parameters for Sergei's tomography procedure automation
# Parameter information is at the end of this file!

#===General Parameters===#
set softwaredir = /data/home/omid_b/Ambient-Noise-Tomography/tomography
set datasetdir = $softwaredir/dataset_final_9Apr

#===Inversion Parameters==#

# "bac" code parameters
set periods = (4 5 6 7 8 9 10 12 14 16 18 20 22 25 27 30 34 40 45 50)
set refvels = (0 0 0 0 0 0  0  0  0  0  0  0  0  0  0  0  0  0  0  0)
set anis_flag = 2
set path_width = 0
set grd_spacing = (80 20)

# "iac" code parameters
set max_iter = 900
set int_sol = 25
set iter = (1 2 3 5 7 10 15 20 30 40 50 70 100 130 160 200 250 300 350 400 500 600 700 800 900)
set dmp = (0.05 0.07 0.07)
set smth = (0.5 0.7 0.7)
set grad_dmp = (0.05 0.07 0.07) # a list of three values

#set dmp = (0.00001 0.00001 0.00001)  #for non-regularized inversions
#set smth = (0.00001 0.00001 0.00001) #for non-regularized inversions
#set grad_dmp = (0.00001 0.00001 0.00001) #for non-regularized inversions

# "xsc" code parameters
set plt_colsum_flag = 0
set xsc_smth_flag = 0
set xsc_scale_limit = (0.5 0.5 0.5)
set xsc_interp_output = (1 0.1)
set xsc_region_only = (1 0.5)

#===Plot Parameters===#
#set gmt_manual_reg = (0 "0/360/45/90")
#set gmt_manual_prj = (0 "F-45/73/20/700p")

set gmt_manual_reg = (1 "281.3/303.5/40.3/51.4")
set gmt_manual_prj = (1 "L292.383/45.8809/40.325617/51.436173/700p")


set plot_flags = (0 1 0 0)
set c_scale_range = (0 3.5)

set annot = (4 3 0.5)
set annot_font_size = 18
set margin_adjust = (0 0)
set raster_dpi = 300

# anisotropy plot parameters:
set anis_bar_factor = (0.9 0.9)
set anis_bar_color = magenta1
set anis_bar_thickness = 5 
set anis_scale_bar_azim = 95 
set anis_scale_bar_value = 2 
set anis_scale_bar_xy = (-60 42) 
set anis_scale_txt_xy = (-60 41.5)

# outlier exclusion parameters
set outliers_setting = (2 0.95)

#===Parameter Information===#
# NOTES: (1) Do not add "/" to the end of the directory paths.
#        (2) List of periods should be given in ascending format.

#-----General Parameters----#
# "softwaredir": full path to the software directory containing BIN, SCRIPTS etc. direcories
# "datasetdir": full path to the datasets directory (scripts are hardwired to list *.disp files in this directory)

#---'bac' Code Parameters---#
# "anis_flag": 0 = none, 1 = 2psi-only, 2 = 2psi and 4psi
# "path_width": path width in km (e.g., 0 or 100)
# "grd_spacing": a list of model and integration grid spacing in km;
#                for example, (200 40)

#---'iac' Code Parameters---#
# "max_iter": maximum number of iterations
# "int_sol": intermediate solutions to output, after different # of iter (next parameter, "iter")
# "iter": a list of number of iterations
# "dmp": a list of norm damping parameters for C, 2psi, 4psi
# "dmp_scale_flag" (hardwired in "init.csh"):
#         a list of norm damp scaling flags, yes(1) or no(0) for C, 2psi, 4psi 
# "dmp_scale_value" (hardwired in "init.csh"):
#         a list of norm damp scaling values for C, 2psi, 4psi 
# "smth": a list of smoothing parameters for C, 2psi, 4psi
# "grad_dmp" (hardwired in "init.csh"):
#            a list of gradient damping parameters for C, 2psi, 4psi

#---'xsc' Code Parameters---#
# "plt_colsum_flag": plot columnsums? yes(1) or no(0)
# "xsc_smth_flag": smoothing in the xsc code? yes(1) or no(0)
# "xsc_scale_limit": a list of scale limits in the xsc code; if < 1, plots as a proportion of the maximum
#                    value of the heterogeneity (useful for a first look); if > 1, plots up to a fixed range 
#                    (i.e. sets the colour scale for the isotropic part of the plot and scales the size of 
#                    bars for the anisotropy); (Default is 0.5 0.5 0.5)
#  Note that the scale limits allow xsc to create its own colour palette file for the model.
#  However, this has been superseded by the scientific colourmaps of Crameri.
#
# "xsc_interp_output": a list of (flag value); 
#                      flag: make gridded output (1) or stick with points (0)
#                      value: grid spacing (deg)
# "xsc_region_only": a list of (flag value); 
#                   flag: plot whole model (0) or just regions covered by paths (1)
#                   value: max distance from nearest path (deg)

#============================#

