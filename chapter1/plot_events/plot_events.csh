#!/bin/csh

# usage: csh plot_events <events_file> <lon0> <lat0>

#===Adjustable Parameters===#
set tectonics_dir = $PWD/tectonics
set concentric_circles = 20
set concentric_circles_label = 60
# ===========================#
clear

set usage = "usage: csh plot_events <events_file> <lon0> <lat0>\n\n<lon0> and <lat0> are coordinates of the study area\n\n<events_file> should have multiple columns as follows:\nDate,Time,Latitude,Longitude,Depth(km),Mag,Mag_type,JulDay,BAZ,GCARC\n"
if ( $#argv != 3  ) then
    printf "$usage\n"
    exit
else
    set events = $argv[1]
    set lon0 = $argv[2]
    set lat0 = $argv[3]
    if ( ! -e $events) then
        printf "Error! Could not find events file: '$events'\n"
        exit()
    else
        set outfile = `readlink -e $events|rev|awk -F"/" '{print $1}'|cut -d'.' -f2-99|rev`
    endif
endif

touch gmt.history
rm -f gmt.{history,conf} $outfile.{tmp,grd}
# build input data ($outfile.tmp): ignore empty lines and those starting with '#'
grep . $events|grep -v '^#'|awk '{print $4,$3}'  > $outfile.tmp

# start GMT script
printf "Tectonics data: $tectonics_dir\n\n"
printf "Generating plot ...\n"

gmt set PS_MEDIA 600x600
gmt set GMT_VERBOSE n
gmt set MAP_FRAME_PEN thin,black
gmt set MAP_GRID_CROSS_SIZE_PRIMARY 0

gmt pscoast -Rg -JE$lon0/$lat0/6.5i -K -P -Di -B5555 -A5000 -Givory3 > $outfile.ps

if ( -d $tectonics_dir ) then
    set data = `ls $tectonics_dir |grep -e '.dat$'|awk '{printf "%s ",$1}'`
    foreach d ( $data )
        cat $tectonics_dir/$d|gmt psxy -R -J -O -P -K -Wthick,azure3 >> $outfile.ps
    end
else
    printf "WARNING! Could not find tectonics data directory in:\n'$tectonics_dir'\n\n"
endif

gmt grdmath -Rd -I120m $lon0 $lat0 SDIST KM2DEG = $outfile.grd
gmt grdcontour $outfile.grd -A$concentric_circles_label -L0/180 -C$concentric_circles -J -P -O -K >> $outfile.ps


cat $outfile.tmp | gmt psxy -R -J -K -O -P -Sc6p -Gblack -Wthin,black >> $outfile.ps

echo $lon0 $lat0|gmt psxy -R -J -O -P -Sa16p -Gred -Wthin,darkred >> $outfile.ps


#remove temporary files
rm -f gmt.{history,conf} $outfile.{tmp,grd}

printf "\nDone!\n"

