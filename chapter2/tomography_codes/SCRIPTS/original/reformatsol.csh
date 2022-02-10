#!/bin/csh
foreach d (0?0 025 035 1?0 2?0)
cd $d
reformat_sol
awk '{print $1,$2}' < dcp > tmp
paste tmp sol_new > alphavalues_$d
cd ..
end
