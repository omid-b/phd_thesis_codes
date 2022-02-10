#!/bin/csh -f

foreach outldir (outlier_info/0??_orig)

cd $outldir

foreach textfile (path_list path_nsl path_sel rhs1 syndat syndif)
sed -i 's:/darbyshire_f/LEBEDEV:/darbyshire_f/SW_TOMOGRAPHY/GREENLAND:g' $textfile
end

cd /home/darbyshire_f/SW_TOMOGRAPHY/GREENLAND

end

