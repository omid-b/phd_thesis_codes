First set all the parameters in "param.csh". This file is loaded in all C-Shell scripts


1) Instrument response change / removal

2) Decimate (resampling)

3) Synchronize

4) Order and rename

5) Make windowing information (wndbbf) file

6) Windowing seismograms and applying bandpass filters

7) Second quality control 

8) Make grid points (inversion nodes)

9) Make kernels using desired charactristic lengths (smoothing value)

10) Make filelists

11) Make phase and Amplitude files (phamp_*)

12) Perform Two-Plane-Wave inversion

# NOTE: Step 5-6 is automated when using tpwt_filtering script
