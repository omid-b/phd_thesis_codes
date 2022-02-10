* sac macro to set up guide window information for windowing in autowndws
* run inside an event directory  dir1 should include ../dirname
* only need input nearest station  and farthest station 
* then use plotpk to pick up the near-begin, near-end far-beginning
* where len= ne-nb
* then use cut_bp.m to cut the data 

echo off
unsetbb all

echo on

* set total length of cut seismogram
* the length of (ctb2 - ctb1) should be 2000-3000 with signals sitting 
*  approximately in the center

setbb ctb1 $ctb1 ctb2 $ctb2

xlim %ctb1 %ctb2

* read in files with nearest and farthest distance

setbb nfile $1
setbb ffile $2

rh %nfile
setbb ndist &1,DIST

rh %ffile
setbb fdist &1,DIST


* 0.001-0.009
r %nfile %ffile
rmean 
taper
p1
bp co .001 .009 n 4 p 2
title on 'bp co .001 .009 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb20 &1,t4
evaluate to ne20 &1,t5
evaluate to fb20 &2,t4
evaluate to len20 %ne20 - %nb20


* 0.001-0.010
r %nfile %ffile
rmean 
taper
p1
bp co .001 .010 n 4 p 2
title on 'bp co .010 .010 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb19 &1,t4
evaluate to ne19 &1,t5
evaluate to fb19 &2,t4
evaluate to len19 %ne19 - %nb19


* 0.001-0.011
r %nfile %ffile
rmean 
taper
p1
bp co .001 .011 n 4 p 2
title on 'bp co .001 .011 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb18 &1,t4
evaluate to ne18 &1,t5
evaluate to fb18 &2,t4
evaluate to len18 %ne18 - %nb18


* 0.002-0.012
r %nfile %ffile
rmean 
taper
p1
bp co .002 .012 n 4 p 2
title on 'bp co .002 .012 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb17 &1,t4
evaluate to ne17 &1,t5
evaluate to fb17 &2,t4
evaluate to len17 %ne17 - %nb17


* 0.003-0.013
r %nfile %ffile
rmean 
taper
p1
bp co .003 .013 n 4 p 2
title on 'bp co .003 .013 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb16 &1,t4
evaluate to ne16 &1,t5
evaluate to fb16 &2,t4
evaluate to len16 %ne16 - %nb16


* 0.004-0.014
r %nfile %ffile
rmean 
taper
p1
bp co .004 .014 n 4 p 2
title on 'bp co .004 .014 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb15 &1,t4
evaluate to ne15 &1,t5
evaluate to fb15 &2,t4
evaluate to len15 %ne15 - %nb15


*0.005-0.015
r %nfile %ffile
rmean 
taper
p1
bp co .005 .015 n 4 p 2
title on 'bp co .005 .015 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb14 &1,t4
evaluate to ne14 &1,t5
evaluate to fb14 &2,t4
evaluate to len14 %ne14 - %nb14


*0.0065-0.0165
r %nfile %ffile
rmean 
taper
p1
bp co .0065 .0165 n 4 p 2
title on 'bp co .0065 .0165 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb13 &1,t4
evaluate to ne13 &1,t5
evaluate to fb13 &2,t4
evaluate to len13 %ne13 - %nb13


*0.008-0.018
r %nfile %ffile
rmean 
taper
p1
bp co .008 .018 n 4 p 2
title on 'bp co .008 .018 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb12 &1,t4
evaluate to ne12 &1,t5
evaluate to fb12 &2,t4
evaluate to len12 %ne12 - %nb12


*0.010-0.020
r %nfile %ffile
rmean 
taper
p1
bp co .010 .020 n 4 p 2
title on 'bp co .010 .020 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb11 &1,t4
evaluate to ne11 &1,t5
evaluate to fb11 &2,t4
evaluate to len11 %ne11 - %nb11


*0.012-0.022
r %nfile %ffile
rmean 
taper
p1
bp co .012 .022 n 4 p 2
title on 'bp co .012 .022 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb10 &1,t4
evaluate to ne10 &1,t5
evaluate to fb10 &2,t4
evaluate to len10 %ne10 - %nb10


*0.015-0.025 
r %nfile %ffile
rmean 
taper
p1
bp co .015 .025 n 4 p 2
title on 'bp co .015 .025 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb9 &1,t4
evaluate to ne9 &1,t5
evaluate to fb9 &2,t4
evaluate to len9 %ne9 - %nb9


*0.017-0.027 
r %nfile %ffile
rmean 
taper
p1
bp co .017 .027 n 4 p 2
title on 'bp co .017 .027 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb8 &1,t4
evaluate to ne8 &1,t5
evaluate to fb8 &2,t4
evaluate to len8 %ne8 - %nb8


*0.020-0.030
r %nfile %ffile
rmean 
taper
p1
bp co .020 .030 n 4 p 2
title on 'bp co .020 .030 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb7 &1,t4
evaluate to ne7 &1,t5
evaluate to fb7 &2,t4
evaluate to len7 %ne7 - %nb7


*0.024-0.034
r %nfile %ffile
rmean 
taper
p1
bp co .024 .034 n 4 p 2
title on 'bp co .024 .034 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb6 &1,t4
evaluate to ne6 &1,t5
evaluate to fb6 &2,t4
evaluate to len6 %ne6 - %nb6


*0.028-0.038
r %nfile %ffile
rmean 
taper
p1
bp co .028 .038 n 4 p 2
title on 'bp co .028 .038 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb5 &1,t4
evaluate to ne5 &1,t5
evaluate to fb5 &2,t4
evaluate to len5 %ne5 - %nb5


*0.032-0.042
r %nfile %ffile
rmean 
taper
p1
bp co .032 .042 n 4 p 2
title on 'bp co .032 .042 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb4 &1,t4
evaluate to ne4 &1,t5
evaluate to fb4 &2,t4
evaluate to len4 %ne4 - %nb4


*0.035-0.045
r %nfile %ffile
rmean 
taper
p1
bp co .035 .045 n 4 p 2
title on 'bp co .035 .045 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb3 &1,t4
evaluate to ne3 &1,t5
evaluate to fb3 &2,t4
evaluate to len3 %ne3 - %nb3


*0.04-0.05
r %nfile %ffile
rmean 
taper
p1
bp co .04 .05 n 4 p 2
title on 'bp co .04 .05 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb2 &1,t4
evaluate to ne2 &1,t5
evaluate to fb2 &2,t4
evaluate to len2 %ne2 - %nb2


*0.045-0.055
r %nfile %ffile
rmean 
taper
p1
bp co .045 .055 n 4 p 2
title on 'bp co .045 .055 n 4 p 2'
p1
ppk
lh t4 t5
evaluate to nb1 &1,t4
evaluate to ne1 &1,t5
evaluate to fb1 &2,t4
evaluate to len1 %ne1 - %nb1


writebbf 'wndbbf'
unsetbb all
cut off
echo off
