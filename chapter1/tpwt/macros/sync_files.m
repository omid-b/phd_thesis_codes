* Change KZTIME to the origin time of the event and cut seismograms.
* NB. Assumes all event and station information has already been placed
* into the SAC headers during preprocessing.
* Change samplerate to 1 sps

r *BHZ* 
synch r on
setbb otime &1,O
evaluate to cotime %otime * (-1.0)
ch ALLT %cotime IZTYPE IO
wh 
if &1,DELTA NE 1.0
 interp d 1.0
 w over
endif
p1
w over

*r *BHN* 
*synch r on
*setbb otime &1,O
*evaluate to cotime %otime * (-1.0)
*ch ALLT %cotime IZTYPE IO
*wh 
*if &1,DELTA NE 1.0
* interp d 1.0
* w over
*endif
*p1
*w over

*r *BHE* 
*synch r on
*setbb otime &1,O
*evaluate to cotime %otime * (-1.0)
*ch ALLT %cotime IZTYPE IO
*wh 
*if &1,DELTA NE 1.0
* interp d 1.0
* w over
*endif
*p1
*w over
