#!/bin/csh
#====Adjustable Parameters====#
#GMT parameters:
set mediaSize = 15ix15i
set mapTitle = ''
set grdSpacing = '0.01d'
#=============================#
clear
printf "This script generates custom 2*stdErr contour and the related plot using GMT.\n\n"

if ($#argv != 3) then
  printf "Error!\n\nUSAGE: ./errMask.csh <gridCovar.xyz> <average velocity> <contour value>\n\n"
  exit
else
  set covargrid = $argv[1]
  set phVel = $argv[2]
  set contour = $argv[3]
endif

touch gmt.history; rm -f gmt.history
touch gmt.conf; rm -f gmt.conf

#===GMT script===#
gmt set FONT_ANNOT_PRIMARY 14p,Helvetica,black FONT_ANNOT_SECONDARY 8p,Helvetica,black \
        FONT_LABEL 12p,Helvetica,black FONT_TITLE 22p,Helvetica-Bold,black FORMAT_GEO_MAP \
        ddd:mm:ssF GMT_VERBOSE n MAP_ANNOT_OBLIQUE 6 MAP_ANNOT_OFFSET 5p MAP_FRAME_PEN \
        thinnest,black MAP_FRAME_TYPE fancy MAP_GRID_CROSS_SIZE_PRIMARY 2 PS_MEDIA "$mediaSize" \
        MAP_TITLE_OFFSET 0.2i  COLOR_NAN white COLOR_FOREGROUND darkred \
        COLOR_BACKGROUND darkblue PS_CHAR_ENCODING ISOLatin1+
        
set lon_l1 = `awk '{print $1}' $covargrid| sort -n |awk 'NR==1'`
set lon_l2 = `awk '{print $1}' $covargrid| sort -nr|awk 'NR==1'`
set lat_l1 = `awk '{print $2}' $covargrid| sort -n |awk 'NR==1'`
set lat_l2 = `awk '{print $2}' $covargrid| sort -nr|awk 'NR==1'`
set center_lon = `echo "$lon_l1 $lon_l2"|awk '{printf "%.2f\n", ($2 - $1)/2 +$1}'`
set center_lat = `echo "$lat_l1 $lat_l2"|awk '{printf "%.2f\n", ($2 - $1)/2 +$1}'`
set area = $lon_l1/$lon_l2/$lat_l1/$lat_l2
set prj = "L$center_lon/$center_lat/$lat_l1/$lat_l2/12i"

set fn = `echo $contour|awk  '{printf "errMask%s",$1}'`

#gridding:
printf "  Gridding ... \r"
gmt blockmean $covargrid -R$area -I$grdSpacing > bm.tmp
gmt surface bm.tmp -R$area -I$grdSpacing -T0 -G$fn.nc
gmt grdmath $fn.nc $phVel DIV 100 MUL = ste.nc

#Making mask grids
gmt grdmath ste.nc 0 $contour INRANGE 0 NAN = errMask.nc
gmt grdmath errMask.nc ste.nc MUL = steMasked.nc
gmt grd2cpt steMasked.nc -E50 -Z -Cjet  > steMasked.cpt
printf "  Gridding ... Done\n"

#plotting
printf "  Plotting ... \r"
gmt psbasemap -R$area -J$prj -Y2i -Ba -BWSne+t"$mapTitle" -K > $fn.ps
gmt grdimage steMasked.nc -CsteMasked.cpt -R$area -J$prj -E300 -K -O >> $fn.ps
gmt grdcontour ste.nc -C0.5 -J$prj -A0.5+f14p -K -O>> $fn.ps
gmt grdcontour ste.nc -C$contour -D|awk -v con=$contour '$3==con {printf " %.10f  %.10f\n",$1,$2}'> $fn.dat
gmt psscale -Dx1i/-0.9i+jTL+w10i/0.4i+h -CsteMasked.cpt -R$area -J$prj -Ba -By+l"2@~\264@~STE (@~\045@~)" -O -K >> $fn.ps
gmt pscoast -R$area -J$prj -Wthin,black -Di -A1000k -Ba -O>> $fn.ps

ps2epsi  $fn.ps $fn.epsi
epstopdf --autorotate=All $fn.epsi
printf "  Plotting ... Done!\n\n"

#remove unnecessary files
rm -f *.cpt gmt.* *.tmp steMasked.nc errMask.nc $fn.epsi $fn.ps $fn.nc ste.nc
