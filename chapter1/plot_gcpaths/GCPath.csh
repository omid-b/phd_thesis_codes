#!/bin/csh

set homedir = $PWD
set grid = data/EstCA_Grd1.dat

clear
cd $homedir

#Study region:
set numNodes = `awk 'NR==2' $grid`
set lon_l1 = `awk 'NR>2' $grid|head -n$numNodes|awk '{print $2}'|sort -n  |awk 'NR==1'`
set lon_l2 = `awk 'NR>2' $grid|head -n$numNodes|awk '{print $2}'|sort -nr |awk 'NR==1'`
set lat_l1 = `awk 'NR>2' $grid|head -n$numNodes|awk '{print $1}'|sort -n  |awk 'NR==1'`
set lat_l2 = `awk 'NR>2' $grid|head -n$numNodes|awk '{print $1}'|sort -nr  |awk 'NR==1'`
set center_lon = `echo "$lon_l1 $lon_l2"|awk '{printf "%.2f\n", ($2 - $1)/2 +$1}'`
set center_lat = `echo "$lat_l1 $lat_l2"|awk '{printf "%.2f\n", ($2 - $1)/2 +$1}'`
set reg = "-75/-58/41.5/50"
set prj = "L$center_lon/$center_lat/$lat_l1/$lat_l2/5i"

printf "Center of study region (lon&lat): $center_lon  $center_lat\n\n"


if (-d GCpaths) rm -rf GCpaths
mkdir GCpaths

@ j=0
foreach bp (`ls $homedir/data|grep "bp[0-9][0-9].xyxy"`)
  @ j++
  set OUT = $homedir/GCpaths/$bp
  gmt set FONT_ANNOT_PRIMARY 10p,Helvetica,black FONT_ANNOT_SECONDARY 8p,Helvetica,black \
        FONT_LABEL 12p,Helvetica,black FONT_TITLE 18p,Helvetica-Bold,black FORMAT_GEO_MAP \
        ddd:mm:ssF GMT_VERBOSE n MAP_ANNOT_OBLIQUE 6 MAP_ANNOT_OFFSET 5p MAP_FRAME_PEN \
        thin,black MAP_FRAME_TYPE plain MAP_GRID_CROSS_SIZE_PRIMARY 2 PS_MEDIA '8ix8i' \
       MAP_TITLE_OFFSET 0.2i

  gmt psbasemap -R$reg -J$prj -Bx3 -By2 -BwsEN -K > $OUT.ps
  @ i=1
  set numLine = `wc -l data/$bp|awk '{print $1}'`
  while ($i <= $numLine)
    printf "   Plotting GC paths: $bp ($i of $numLine)                \r" 
    awk NR==$i $homedir/data/$bp|awk '{printf "%f %f\n%f %f\n",$1,$2,$3,$4}'|psxy -R$reg -J$prj -W0.05p -O -K -P >> $OUT.ps
    @ i++
  end
  printf "   Plotting GC paths ........... Done!           \n\n"
  
  gmt pscoast -R$reg -J$prj -Di -Wthin,red2 -A10000 -K -O  >> $OUT.ps
  #awk '{printf "%11.6f %11.6f\n",$1,$2}' $homedir/mask.xy|gmt psxy -R$reg -J$prj -Sc0.1i -Gred -O -K >> $OUT.ps
  awk '{printf "%11.6f %11.6f\n",$2,$3}' $homedir/data/stations.xy|gmt psxy -R$reg -J$prj -Si0.15i -Gnavyblue -Wthinnest,white -O -K >> $OUT.ps
  set label = `awk "NR==$j" $homedir/data/titles.dat`
  echo $label|pstext -J$prj -R$reg -F+f14p,Helvetica,black -Gwhite -O >> $OUT.ps
  ps2epsi $OUT.ps $OUT.eps
  epstopdf $OUT.eps
end


