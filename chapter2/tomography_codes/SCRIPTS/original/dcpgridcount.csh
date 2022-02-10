#!/bin/csh -f

# USAGE: dcpgridcount.csh period
# where period is the best path coverage, as used for making 1D curves.

set bestper=$1

rm -f resnos
awk '{print $1,$2}' < $bestper/dcp > gridpoints
sort -n gridpoints > grid_sorted
awk '{print $1"-"$2}' < grid_sorted > coordinates

set numresults = `wc -l $bestper/dcp | awk '{print $1}' `

set c = 1
while ( $c <= $numresults)
 echo "c $c" >> resnos
 @ c = $c + 1
end

paste grid_sorted resnos | awk '{print $1,$2,$3""$4}' > cellcoords
awk '{ \
if ($1>180.00000) print $1-360,$2,$3 \
else print $1,$2,$3 \
}' < cellcoords > cellcoords-map

