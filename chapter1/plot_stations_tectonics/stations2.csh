#!/bin/csh
#Make a topography and bathymetery (Histogram equalized) map from desired area.
#----Adjustable Parameters----
set ps = 'stations2.ps'
set gReg = '-82/36/-51/57+r' #region of Topo/Bath gridding (Should be larger than the desired area if a conical/azimuthal projection is selected!)
set reg = '-77/41/-58/50+r' #region (-R tag)
set prj = 'L-65/46.7/44/48/6.5i' #projection (-J tag)
set coastlineRes = 'h'
set gRes = '1m' #Grid sampling interval
set minArea = '300k' #min Area to be plotted (-A option in pscoast)
set topoData = data/topo.b
set geology=/data/LITHOPROBE-TECTONICS
#example for mercator projection (uncomment following 3lines to have a map of Iran!)
#set gReg = '42/22/65/42+r' #region of Topo/Bath gridding (Should be larger than the desired area if a conical/azimuthal projection is selected!)
#set reg = '42/22/65/42+r' #region (-R tag)
#set prj = 'M6i' #projection (-J tag)

#set gReg = '-145/215/-90/90' #region of Topo/Bath gridding (Should be larger than the desired area if a conical/azimuthal projection is selected!)
#set reg = '-145/215/-90/90' #region (-R tag)
#set prj = 'Y35/30/6.5i' #projection (-J tag)
#-----------------------------

clear
if (-e gmt.conf) rm -f gmt.conf
if (-e gmt.history) rm -f gmt.history
if (-e $ps) rm -f $ps

gmt set FONT_ANNOT_PRIMARY 10p,Helvetica,black FONT_ANNOT_SECONDARY 8p,Helvetica,black \
        FONT_LABEL 10p,Helvetica,black FONT_TITLE 18p,Helvetica-Bold,black FORMAT_GEO_MAP \
        ddd:mm:ssF GMT_VERBOSE n MAP_ANNOT_OBLIQUE 6 MAP_ANNOT_OFFSET 5p MAP_FRAME_PEN \
        thick,black MAP_FRAME_TYPE plain MAP_GRID_CROSS_SIZE_PRIMARY 2 PS_MEDIA 10ix10i MAP_TITLE_OFFSET 0.2i PS_CHAR_ENCODING Standard+

set SCALE2D="-R$reg -J$prj"
set geology=/data/LITHOPROBE-TECTONICS

#set OUT=canada-tecto.ps
#set OUT=orogens2016/tho-north-tecto.ps
set OUT=$ps
set FLAGS_FIRST='-V -K -P'
set FLAGS='-O -K -P'
set FLAGS_LAST='-V -O -P'
#COLOURS
set Archean1='-Gdeepskyblue'
set Archean2b='-Gdeepskyblue'
set Archean2='-Gdeepskyblue'
set Archean3='-Gdeepskyblue'

set PaleoProt1='-Gmediumseagreen'
set PaleoProt2='-Gmediumseagreen'
set PaleoProt3a='-Gmediumseagreen'
set PaleoProt3='-Gmediumseagreen'

set MesoProt1='-Gblue'
set MesoProt1b='-Gblue'
set MesoProt2='-Gblue'
set MesoProt3a='-Gmediumseagreen'
set MesoProt3='-Gmediumseagreen'

set Paleozoic1='-Ggold'
set Paleozoic2='-Ggold'
set Paleozoic3='-Ggold'

set MesoTert1='-G128/0/0'
set MesoTert2='-G128/0/0'
set MesoTert2='-G255/0/0'
set MesoTert3='-G214/0/0'
set MesoTert3='-G250/214/255'
set Recent='-G250/214/255'
set Recent='-G194/143/240'

set Mask='-G245/245/245'

set FLAGS_FIRST='-K -P'
set FLAGS='-O -K -P'
set FLAGS_LAST='-O -P'


gmt psbasemap $SCALE2D $FLAGS_FIRST -Bxa4 -Bya2 -BEsNw -Y4 > $OUT
#gmt pscoast $SCALE2D $FLAGS -A1500 -G245 -S255 -Di -Na -W >> $OUT
gmt pscoast $SCALE2D $FLAGS -A1500 -G240 -S255 -Di -W >> $OUT

#SLAVE ----------------------------
#ARCHEAN1
gmt psxy $geology/sleepy_dragon_belt.ll  $SCALE2D $FLAGS $Archean1 -Wthick,black -: >> $OUT
gmt psxy $geology/anton_belt.ll  $SCALE2D $FLAGS $Archean1 -Wthick,black -: >> $OUT
gmt psxy $geology/eokuk_uplift.ll  $SCALE2D $FLAGS $Archean1 -Wthick,black -: >> $OUT
#
#ARCHEAN2
gmt psxy $geology/contwoyto-hacket_river.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/goulburn_supergroup.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
#
#ARCHEAN3
#
#WOPMAY/HOTTAH ----------------------------
#PALEOPROTERZOIC2
gmt psxy $geology/coronation_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/great_bear_arc.ll $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/hottah_terrane.ll $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
#PALEOPROTERZOIC3
gmt psxy $geology/fort_simpson_arc.ll $SCALE2D $FLAGS $PaleoProt3 -Wthick,black -: >> $OUT
gmt psxy $geology/nahanni_domain.ll $SCALE2D $FLAGS $PaleoProt3 -Wthick,black -: >> $OUT
gmt psxy $geology/fort_nelson_arc.ll $SCALE2D $FLAGS $PaleoProt3 -Wthick,black -: >> $OUT
#

#RECENT
gmt psxy $geology/pacific_rim_and_crescent.ll $SCALE2D $FLAGS $Recent -Wthick,black -: >> $OUT
gmt psxy $geology/olympic_terrane.ll $SCALE2D $FLAGS $Recent -Wthick,black -: >> $OUT

#ABT ----------------------------
#ARCHEAN
gmt psxy $geology/nova_domain.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/rae_craton2.ll   $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/hearne_craton.ll  $SCALE2D $FLAGS  $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/snowbird_zone.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/medicine_hat_block.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/west_sed_basin.ll  $SCALE2D $FLAGS $Archean2  -: >> $OUT
gmt psxy $geology/great_falls_tz.ll $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/wyoming_province.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
#
#PALEOPROTEROZOIC2
gmt psxy $geology/wabamun_terrane.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/buffalo_head_terrane.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
gmt psxy $geology/thorsby_domain.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/chinchaga_domain.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/kiskatinaw_domain.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
gmt psxy $geology/lacombe_domain.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/rimbey_arc.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/taltson_arc.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/queenmaud.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/baker_basin_1.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/baker_basin_2.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/baker_basin_3.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/ford_penrhyn_1.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
#PALEOPROTEROZOIC3
gmt psxy $geology/ksituan_arc.ll  $SCALE2D $FLAGS $PaleoProt3 -Wthick,black -: >> $OUT
gmt psxy $geology/thelon_basin_1.ll   $SCALE2D $FLAGS $PaleoProt3a -Wthick,black -: >> $OUT
gmt psxy $geology/thelon_basin_2.ll   $SCALE2D $FLAGS $PaleoProt3a -Wthick,black -: >> $OUT
#
gmt psxy $geology/ancestral_n_america.ll  $SCALE2D $FLAGS $MesoTert1 -Wthick,black -: >> $OUT

#THOT GEOLOGY ----------------------------
#
#PALEOPROTEROZOIC2
gmt psxy $geology/wollaston_foldbelt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/saskatoon.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/wathaman_batholith.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/saskatoon.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/peter_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/rottenstone_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/laronge_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/seal_river.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
gmt psxy $geology/glennie_belt.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/flin_flon_belt.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/kisseynew_belt.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/tabbernor_fault_zone.ll  $SCALE2D $FLAGS   $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/assinboia.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/great_island.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/nejaniuni.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
#
#PALEOPROTEROZOIC3
gmt psxy $geology/athabasca_basin.ll  $SCALE2D $FLAGS  $PaleoProt3a -Wthick,blue -: >> $OUT
#
#WSUP GEOLOGY ----------------------------
#
#ARCHEAN2a?
gmt psxy $geology/northern_superior_superterrane.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/northern_superior_superterrane2.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/oxford-stull_terrane.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/north_caribou_terrane.ll   $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/uchi_belt.ll  $SCALE2D $FLAGS $Archean2   -Wthick,black -: >> $OUT
#
#ARCHEAN2b?
gmt psxy $geology/winnipeg_river_belt.ll  $SCALE2D $FLAGS $Archean2b -Wthick,black -: >> $OUT
gmt psxy $geology/bird_river.ll $SCALE2D $FLAGS $Archean2b -Wthick,black -: >> $OUT
gmt psxy $geology/english_river_belt.ll  $SCALE2D $FLAGS $Archean2b -Wthick,black -: >> $OUT
gmt psxy $geology/wabigoon_belt.ll   $SCALE2D $FLAGS $Archean2b -Wthick,black -: >> $OUT
#
#ARCHEAN3
gmt psxy $geology/wawa_belt.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/quetico_belt.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
#
#PALEOPROT1
gmt psxy $geology/huronian.ll   $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT

#LE GEOLOGY ----------------------------
#PALEOZOIC1
gmt psxy $geology/humber_belt.ll2  $SCALE2D $FLAGS $Paleozoic1 -Wthick,black -: >> $OUT
gmt psxy $geology/dunnage_notredame.ll  $SCALE2D $FLAGS $Paleozoic1 -Wthick,black -: >> $OUT
#
#PALEOZOIC2
gmt psxy $geology/dunnage_belt.ll2  $SCALE2D $FLAGS $Paleozoic2 -Wthick,black -: >> $OUT
gmt psxy $geology/gander_belt.ll2 $SCALE2D $FLAGS $Paleozoic2 -Wthick,black -: >> $OUT
#
#PALEOZOIC3
gmt psxy $geology/avalon_belt.ll2  $SCALE2D $FLAGS $Paleozoic3 -Wthick,black -: >> $OUT
gmt psxy $geology/meguma_belt.ll2  $SCALE2D $FLAGS $Paleozoic3 -Wthick,black -: >> $OUT

#ECSOOT GEOLOGY ----------------------------
#ARCHEAN1
gmt psxy $geology/sugluk_terrane.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/hearne_craton2.ll  $SCALE2D $FLAGS  $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/archean_ungava_orogen.ll $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/cape_smith_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/nain_prov.ll  $SCALE2D $FLAGS $Archean1 -Wthick,black -: >> $OUT
gmt psxy $geology/inukjuak.ll $SCALE2D $FLAGS $Archean2  -Wthick,black -:>> $OUT
gmt psxy $geology/tikkerutuk-bienville.ll  $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/lake_minto.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/qalluviartuuq.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/goudalie.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/utsalik.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/douglas_harbour.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/ashuanipi.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/thompson-superior_boundary_zone.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#
#PALEOPROTEROZIC (1.7-1.9)
gmt psxy $geology/burwell_domain.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/lac_lomier_complex.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/tg_terrane.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/calc_alk_arc.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/nain_prov_ext.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/sed_volc_belt.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/sed_volc_beltsii.ll  $SCALE2D $FLAGS $PaleoProt2 -Wthick,black  -: >> $OUT
gmt psxy $geology/core_zone.ll  $SCALE2D $FLAGS  $PaleoProt2 -Wthick,black -: >> $OUT
#
#MESOPROTEROZOIC
gmt psxy $geology/nain_plutonic_suite.ll  $SCALE2D $FLAGS $MesoProt2 -Wthick,black  -: >> $OUT
gmt psxy $geology/sed_cover.ll  $SCALE2D $FLAGS $MesoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/unknown5.ll  $SCALE2D $FLAGS $MesoProt2 -Wthick,black  -: >> $OUT
gmt psxy $geology/grenville_provinceb.ll  $SCALE2D $FLAGS $MesoProt2 -Wthick,black -: >> $OUT

#ABITIBI-GRENVILLE GEOLOGY ----------------------------
#ARCHEAN2
gmt psxy $geology/penokean.ll $SCALE2D $FLAGS $Archean2 -Wthick,black -: >> $OUT
gmt psxy $geology/la_grande_river.ll  $SCALE2D $FLAGS  $Archean2b  -Wthick,black -: >> $OUT
#
#ARCHEAN3
gmt psxy $geology/opatica.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/superior_proterozoic.ll $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/opinaca_river.ll  $SCALE2D $FLAGS  $Archean3  -Wthick,black -: >> $OUT
gmt psxy $geology/nemiscau.ll  $SCALE2D $FLAGS  $Archean3  -Wthick,black -: >> $OUT
gmt psxy $geology/abitibi.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/pontiac.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/ABG_granitoids.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
gmt psxy $geology/ABG_mafics.ll  $SCALE2D $FLAGS $Archean3 -Wthick,black -: >> $OUT
#
#PALEOPROTEROZOIC
gmt psxy $geology/kapuskasing.ll $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
gmt psxy $geology/wisconsin_magmatic_zone.ll $SCALE2D $FLAGS $PaleoProt2 -Wthick,black -: >> $OUT
#

#MESOPROTEROZOIC3
gmt psxy $geology/grenville_province_paleozoic.ll $SCALE2D $FLAGS $Paleozoic1 -Wthick,black -: >> $OUT
gmt psxy $geology/grenville_provincea.ll $SCALE2D $FLAGS $MesoProt3a -Wthick,black -: >> $OUT
gmt psxy $geology/gren_anorthosite.ll $SCALE2D $FLAGS $MesoProt3a -Wthick,black -: >> $OUT
gmt psxy $geology/allochthonous_polycyclic.ll  $SCALE2D $FLAGS $MesoProt3a -Wthick,black -: >> $OUT
gmt psxy $geology/allochthonous_moncyclic.ll $SCALE2D $FLAGS $MesoProt3a -Wthick,black -: >> $OUT
gmt psxy $geology/grenville_st.law.ll $SCALE2D $FLAGS $MesoProt3a -Wthick,black -: >> $OUT


#Rift
gmt psxy $geology/kr.ll $SCALE2D $FLAGS $MesoProt3 -Wthick,black -: >> $OUT
gmt psxy $geology/mrv.ll  $SCALE2D $FLAGS -G0/102/204 -Wthick,black -: >> $OUT



# GEOLOGICAL DOMAIN OUTLINES

#THOT GEOLOGY
gmt psxy $geology/wollaston_foldbelt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/saskatoon.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/wathaman_batholith.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/saskatoon.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/peter_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/rottenstone_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/laronge_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/seal_river.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/great_island.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nejaniuni.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/flin_flon_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/glennie_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/tabbernor_fault_zone.ll  $SCALE2D $FLAGS   -Wthick,white -: >> $OUT
gmt psxy $geology/kisseynew_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/assinboia.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT


#ABT GEOLOGY
gmt psxy $geology/hearne_craton.ll $SCALE2D $FLAGS   -Wthick,white -: >> $OUT
gmt psxy $geology/rae_craton2.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/snowbird_zone.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/medicine_hat_block.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/great_falls_tz.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/wyoming_province.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/rimbey_arc.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/athabasca_basin.ll  $SCALE2D $FLAGS   -Wthick,white -: >> $OUT
gmt psxy $geology/queenmaud.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/thelon_basin_1.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/thelon_basin_2.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/baker_basin_1.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/baker_basin_2.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/baker_basin_3.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/ford_penrhyn_1.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT

#Cordillera

gmt psxy $geology/lacombe_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/thorsby_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/wabamun_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/buffalo_head_terrane.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/chinchaga_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/ksituan_arc.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/kiskatinaw_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nova_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/hottah_terrane.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/great_bear_arc.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/fort_simpson_arc.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nahanni_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/fort_nelson_arc.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/coronation_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/anton_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/contwoyto-hacket_river.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/sleepy_dragon_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/goulburn_supergroup.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/eokuk_uplift.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/ancestral_n_america.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/kootenay.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/cassiar.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/slide_mountain.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/undivided_metamorphic.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nisling.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/dorsey_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/monashee.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/stikinia.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/windy-mckinley_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/taku_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/quesnellia.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/cache_creek.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/coast_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/alexander_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/chugach_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/yakutat_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/wrangellia.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/pacific_rim_and_crescent.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/olympic_terrane.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/scord_plutons.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT

#WSUP GEOLOGY
gmt psxy $geology/uchi_belt.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/english_river_belt.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/bird_river.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/wabigoon_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/winnipeg_river_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/oxford-stull_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/north_caribou_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/northern_superior_superterrane.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/northern_superior_superterrane2.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/quetico_belt.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/wawa_belt.ll $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/huronian.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT

#LE GEOLOGY
gmt psxy $geology/humber_belt.ll2  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/dunnage_belt.ll2  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/dunnage_notredame.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/gander_belt.ll2 $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/avalon_belt.ll2  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/meguma_belt.ll2  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT


#ECSOOT GEOLOGY
gmt psxy $geology/ashuanipi.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/tikkerutuk-bienville.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/cape_smith_belt.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/sugluk_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/core_zone.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/sed_volc_belt.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/calc_alk_arc.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/nain_prov_ext.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nain_prov.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/burwell_domain.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/lac_lomier_complex.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/tg_terrane.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/unknown5.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/nain_plutonic_suite.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/sed_cover.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/sed_volc_beltsii.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT
gmt psxy $geology/allochthonous_polycyclic.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/allochthonous_moncyclic.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/inukjuak.ll $SCALE2D $FLAGS   -Wthick,white -:>> $OUT
gmt psxy $geology/lake_minto.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/goudalie.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/qalluviartuuq.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/utsalik.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/douglas_harbour.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/archean_ungava_orogen.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/thompson-superior_boundary_zone.ll  $SCALE2D $FLAGS  -Wthick,white -: >> $OUT



#ABITIBI-GRENVILLE GEOLOGY
gmt psxy $geology/opatica.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/opinaca_river.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/la_grande_river.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/pontiac.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/nemiscau.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/abitibi.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/superior_proterozoic.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/grenville_province.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/ABG_granitoids.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/ABG_mafics.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/gren_anorthosite.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/kapuskasing.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/penokean.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/kr.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/mrv.ll  $SCALE2D $FLAGS -Wthick,white -: >> $OUT
gmt psxy $geology/wisconsin_magmatic_zone.ll $SCALE2D $FLAGS -Wthick,white -: >> $OUT

#MASK
#gmt psxy $geology/mask.ll  $SCALE2D $FLAGS $Mask -Wfaint,black -: >> $OUT
#gmt psxy $geology/feather_edge.ll $SCALE2D $FLAGS -Wthick,black,20_20:20 -: >> $OUT


gmt pscoast $SCALE2D $FLAGS -I1 -A1500 -S255 -Di -Na -W >> $OUT



#Omid's study region:

#gmt pscoast -R$reg -J$prj -Wthinnest,black -D$coastlineRes -A$minArea -N1thinnest/SNOW2 -O -K>> $ps

gmt psxy $geology/faults/grenville_abitibi_front.ll $FLAGS $SCALE2D -Sf0.3/0.3+r -Wthickest,tomato2 -: >> $OUT

gmt psxy $geology/faults/appalachian_struc_front.ll2 $FLAGS $SCALE2D -Sf0.3/0.3+r -Wthickest,tomato2 -: >> $OUT

echo "-66.0 46.2 APPALACHIAN"|gmt pstext $FLAGS $SCALE2D -F+a45 -Gwhite >> $OUT
echo "-72 48.5 GRENVILLE"|gmt pstext $FLAGS $SCALE2D -F+a45 -Gwhite >> $OUT
echo "-76.5 48.8 SUPERIOR"|gmt pstext $FLAGS $SCALE2D -F+a45 -Gwhite >> $OUT

#gmt psxy data/grid.dat -R$reg -J$prj -K -O -P -Sc0.07i -Gblack -Wthin,white  >> $ps
gmt psxy data/sta/staCN -R$reg -J$prj -Sh0.15i -Glightpink -Wthick,black -O -K>> $ps
gmt psxy data/sta/staNE -R$reg -J$prj -Sc0.13i -Gblue -Wthick,black -O -K>> $ps
gmt psxy data/sta/staTA -R$reg -J$prj -Si0.15i -Gmagenta -Wthinnest,midnightblue -O -K>> $ps
gmt psxy data/sta/staUS -R$reg -J$prj -Ss0.17i -Gdodgerblue3 -Wthick,black -O -K>> $ps
gmt psxy data/sta/staX8 -R$reg -J$prj -Sc0.13i -Ggoldenrod -Wthick,black -O -K>> $ps
gmt psxy data/sta/staY6 -R$reg -J$prj -Sd0.15i -Gmaroon -Wthick,darkred -O -K >> $ps





echo "-65.0 44.5 Meguma"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-63.9 45.59 Avalonia"|gmt pstext $FLAGS $SCALE2D -F+a0+f7p  >> $OUT
echo "-66.9 46.7 Ganderia"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-67.0 47.6 Dunnage"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-67.0 48.5 Humber"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-73.0 48.5 APB"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-74.1 48.7 PB"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT
echo "-75 46.2 AMB"|gmt pstext $FLAGS $SCALE2D -F+a45+f7p  >> $OUT

#globe
#gmt pscoast -Rg -JA280/30/2.5i -X-0.9i -Y-0.2i -Ba -Dc -A50000 -Gdarkgreen -Slightskyblue -Wthinnest,black -P -O -K>> $ps
#echo -66.25 45.5|gmt psxy -R -J -Ss0.15i -Wthin,red -O -K>> $ps

#gmt pscoast -Rg -JE-66.25/45.5/2.5i -X-0.9i -Y-0.2i -O -K -P -Di -Ba -Bwesn+gwhite  -A5000 -Ggray50 >> $ps
#gmt grdmath -Rd -I60m -66.25 45.5 SDIST 111.13 DIV = dist.grd
#gmt grdcontour dist.grd -A60 -L0/160 -C20 -JE-66.25/45.5/2.5i -P -Vn -O -K >> $ps
#@ i=1
#foreach evt (`cat data/events.xy|awk '{print $1}'`)
#  cat data/events.xy|awk "NR==$i"|awk '{print $1,$2}'|gmt psxy -Rg -JE-66.25/45.5/2.5i -K -O -P -Sc4p -Gblack -Wthin,black >> $ps
#  @ i++
#end
#echo -66.25 45.5|gmt psxy -Rg -JE-66.25/45.5/2.5i -O -P -K -Sa16p -Gred -Wthin,black >> $ps

#legend
gmt psbasemap -R0.5/10/0/2  -JX3.0i/0.7i -X3.45i -Y0.05i -BWSEN+gwhite -Bx0 -By0 -O -K>> $ps

echo 3.5 1.5|gmt psxy -R -J -Si0.15i -Gmagenta -Wthinnest,midnightblue -O -K>> $ps
echo 4 1.5 TA|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K>> $ps

echo 3.5 1|gmt psxy -R -J -Ss0.17i -Gdodgerblue3 -Wthick,black -O -K>> $ps
echo 4 1 US|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K>> $ps

echo 3.5 0.5|gmt psxy -R -J -Sd0.15i -Gmaroon -Wthick,darkred -O -K >> $ps
echo 4 0.5 Y6|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K>> $ps


echo 1 1.5|gmt psxy -R -J -Sh0.15i -Glightpink -Wthick,black -O -K>> $ps
echo 1.5 1.5 CN|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K>> $ps

echo 1 1.0|gmt psxy -R -J -Sc0.13i -Gblue -Wthick,black -O -K>> $ps
echo 1.5 1.0 NE|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K>> $ps

echo 1 0.5|gmt psxy -R -J -Sc0.13i -Ggoldenrod -Wthick,black -O -K>> $ps
echo 1.5 0.5 X8|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K >> $ps

cat << EOF > temp.dat
5.5 1.7
6.5 1.7
6.5 1.3
5.5 1.3
5.5 1.7
EOF

gmt psxy temp.dat -R -J $Archean1 -Wthick,black -O -K >> $ps
echo 6.7 1.5 Archean|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K >> $ps
#Archean1 PaleoProt1 Paleozoic1

cat << EOF > temp.dat
5.5 1.2
6.5 1.2
6.5 0.8
5.5 0.8
5.5 1.2
EOF

gmt psxy temp.dat -R -J $PaleoProt1 -Wthick,black -O -K >> $ps
echo 6.7 1.0 Proterozoic|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O -K >> $ps

cat << EOF > temp.dat
5.5 0.7
6.5 0.7
6.5 0.3
5.5 0.3
5.5 0.7
EOF

gmt psxy temp.dat -R -J $Paleozoic1 -Wthick,black -O -K >> $ps
echo 6.7 0.5 Paleozoic|gmt pstext -R -J -N -F+f12p,Helvetica-Bold+jML -O >> $ps



ps2epsi $ps
epstopdf stations2.epsi
#rm -f gmt.* $ps *.nc
