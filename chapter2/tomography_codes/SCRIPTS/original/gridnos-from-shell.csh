#!/bin/csh -f

#foreach d (0?0 0?5)
foreach d (025 050 070)

cd $d

get_gridnos
/data/home/darbyshire_f/SW_TOMOGRAPHY/SCRIPTS/plot-knotnos.gmt $d gridknots

cd ..

end

