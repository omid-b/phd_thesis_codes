#!/bin/csh -f

ls curve* > curvelist
awk -F_ '{print $1,$2,$3}' < curvelist | sort -n -k2 > tmp
paste tmp cellcoords > rnm
awk '{print "mv "$1"_"$2"_"$3,$6".disp"}' < rnm > rnm.csh
csh rnm.csh
rm -f rnm* tmp
