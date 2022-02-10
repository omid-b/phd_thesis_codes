#!/bin/csh -f

foreach dir (0?0 0?5)
cp $dir/plcg.ps plots-groupmaps/plcg-$dir.ps
end
