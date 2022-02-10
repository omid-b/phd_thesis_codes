echo on

 setbb cut1 $cut1
 setbb cut2 $cut2
 evaluate to cut1 %cut1 - 50
 evaluate to cut2 %cut2 + 50
    cut %cut1 %cut2
    evaluate to totlen %cut2 - %cut1
    evaluate to tprfrac 50 / %totlen

     r $infile
     taper w %tprfrac
     w temp2
    cuterr fillz
    cut 0 2000
    r temp2
    cuterr u
     w $outfile
     cut off
echo off

sc rm temp?

