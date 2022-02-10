#!/bin/csh

foreach param (p1 p2)
cp /data/home/bagherpur_o/Scripts/2PW/$param /data/home/bagherpur_o/Scripts/2PW/param.csh
echo 'y'|csh make_filelists.csh
echo 'y'|csh make_phamps.csh
echo 'y'|csh run1D.csh
echo 'y'|csh make_filelists.csh
echo 'y'|csh make_phamps.csh
echo 'y'|csh make_kernels.csh
echo 'y'|csh run2D.csh
echo 'y'|csh run2Dkern.csh
echo 'y'|csh plot_gridDisp.gmt
mv /data/home/bagherpur_o/2PWT_EstCA_final/run?D* /data/home/bagherpur_o/2PWT_EstCA_final/runArchive/
end
