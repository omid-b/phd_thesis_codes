*sac macro file for automatically windowing and filtering all the stations
*in a directory for a particular event.  Window parameters should be based
*on previous examination of filtered records at a near and far station of the
*array - then linearly interpolate windows based on distance
*
*To avoid useless files, should previously have eliminated files that aren't
*to be used.
*
*Should have previously run setupwndws macro
* correct the phase shift ahead of pi/2 of horizontal component relative to
* vertical component 


echo off
readbbf 'wndbbf'

evaluate to ddist %fdist - %ndist
evaluate to tctb2 %ctb2

do file wild D*.Z
 setbb fn1 $file
 rh %fn1
 setbb dst &1,DIST
 setbb end &1,E
 if %tctb2 GT %end
   evaluate to tctb2 %end
 endif 
 evaluate to disn %dst - %ndist
  cut %ctb1 %tctb2

 do BANDP from 1 to 20 by 1
  r %fn1
  cut off
  rmean
  taper

* add 50 s to beginning and end of rect. window, to be tapered   

  if $BANDP EQ 1
    setbb lent %len1
    if %lent GT 0
    bp co .045 .055 n 4 p 2
    setbb SUFIX 'bp01' 
    evaluate to cut11 ( %fb1 - %nb1 ) * %disn / %ddist + %nb1 - 50
     %cut11
    evaluate to cut12 %cut11 + %len1 + 100
    endif               	
    if %fb1 LE  %nb1
    setbb lent 0
    endif

  elseif $BANDP EQ 2 
    setbb lent %len2
    if %lent GT 0
    bp co .04 .05 n 4 p 2
    setbb SUFIX 'bp02' 
    evaluate to cut11 ( ( %fb2 - %nb2 ) * %disn / %ddist + %nb2 - 50 )
     %cut11
    evaluate to cut12 %cut11 + %len2 + 100
    endif
    if %fb2 LE %nb2
    setbb lent 0
    endif

  elseif $BANDP EQ 3
    setbb lent %len3
    if %lent GT 0
    bp co .035 .045 n 4 p 2
    setbb SUFIX 'bp03' 
    evaluate to cut11 ( %fb3 - %nb3 ) * %disn / %ddist + %nb3 - 50
    evaluate to cut12 %cut11 + %len3 + 100
    endif
    if %fb3 LE %nb3
    setbb lent 0
    endif
    
  elseif $BANDP EQ 4 
    setbb lent %len4
    if %lent GT 0
    bp co .032 .042 n 4 p 2
    setbb SUFIX 'bp04' 
    evaluate to cut11 ( %fb4 - %nb4 ) * %disn / %ddist + %nb4 - 50
    evaluate to cut12 %cut11 + %len4 + 100
    endif
    if %fb4 LE %nb4
    setbb lent 0
    endif
    
  elseif $BANDP EQ 5 
    setbb lent %len5
    if %lent GT 0
    bp co .028 .038 n 4 p 2
    setbb SUFIX 'bp05' 
    evaluate to cut11 ( %fb5 - %nb5 ) * %disn / %ddist + %nb5 - 50
    evaluate to cut12 %cut11 + %len5 + 100
    endif
    if %fb5 LE %nb5
    setbb lent 0
    endif
    
  elseif $BANDP EQ 6 
    setbb lent %len6
    if %lent GT 0
    bp co .024 .034 n 4 p 2
    setbb SUFIX 'bp06' 
    evaluate to cut11 ( %fb6 - %nb6 ) * %disn / %ddist + %nb6 - 50
    evaluate to cut12 %cut11 + %len6 + 100
    endif
    if %fb6 LE %nb6
    setbb lent 0
    endif
    
  elseif $BANDP EQ 7 
    setbb lent %len7
    if %lent GT 0
    bp co .02 .03 n 4 p 2
    setbb SUFIX 'bp07' 
    evaluate to cut11 ( %fb7 - %nb7 ) * %disn / %ddist + %nb7 - 50
    evaluate to cut12 %cut11 + %len7 + 100
    endif
    if %fb7 LE %nb7
    setbb lent 0
    endif
    
  elseif $BANDP EQ 8 
    setbb lent %len8
    if %lent GT 0
    bp co .017 .027 n 4 p 2
    setbb SUFIX 'bp08' 
    evaluate to cut11 ( %fb8 - %nb8 ) * %disn / %ddist + %nb8 - 50
    evaluate to cut12 %cut11 + %len8 + 100
    endif
    if %fb8 LE %nb8
    setbb lent 0
    endif
    
  elseif $BANDP EQ 9 
    setbb lent %len9
    if %lent GT 0
    bp co .015 .025 n 4 p 2
    setbb SUFIX 'bp09' 
    evaluate to cut11 ( %fb9 - %nb9 ) * %disn / %ddist + %nb9 - 50
    evaluate to cut12 %cut11 + %len9 + 100
    endif
    if %fb9 LE %nb9
    setbb lent 0
    endif
    
  elseif $BANDP EQ 10 
    setbb lent %len10
    if %lent GT 0
    bp co .012 .022 n 4 p 2
    setbb SUFIX 'bp10' 
    evaluate to cut11 ( %fb10 - %nb10 ) * %disn / %ddist + %nb10 - 50
    evaluate to cut12 %cut11 + %len10 + 100
    endif
    if %fb10 LE %nb10
    setbb lent 0
    endif
    
  elseif $BANDP EQ 11 
    setbb lent %len11
    if %lent GT 0
    bp co .01 .02 n 4 p 2
    setbb SUFIX 'bp11' 
    evaluate to cut11 ( %fb11 - %nb11 ) * %disn / %ddist + %nb11 - 50
    evaluate to cut12 %cut11 + %len11 + 100
    endif
    if %fb11 LE %nb11
    setbb lent 0
    endif
  
  elseif $BANDP EQ 12 
    setbb lent %len12
    if %lent GT 0
    bp co .008 .018 n 4 p 2
    setbb SUFIX 'bp12' 
    evaluate to cut11 ( %fb12 - %nb12 ) * %disn / %ddist + %nb12 - 50
    evaluate to cut12 %cut11 + %len12 + 100
    endif
    if %fb12 LE %nb12
    setbb lent 0
    endif

  elseif $BANDP EQ 13 
    setbb lent %len13
    if %lent GT 0
    bp co .0065 .0165 n 4 p 2
    setbb SUFIX 'bp13' 
    evaluate to cut11 ( %fb13 - %nb13 ) * %disn / %ddist + %nb13 - 50
    evaluate to cut12 %cut11 + %len13 + 100
    endif
    if %fb13 LE %nb13
    setbb lent 0
    endif

  elseif $BANDP EQ 14 
    setbb lent %len14
    if %lent GT 0
    bp co .005 .015 n 4 p 2
    setbb SUFIX 'bp14' 
    evaluate to cut11 ( %fb14 - %nb14 ) * %disn / %ddist + %nb14 - 50
    evaluate to cut12 %cut11 + %len14 + 100
    endif
    if %fb14 LE %nb14
    setbb lent 0
    endif

  elseif $BANDP EQ 15 
    setbb lent %len15
    if %lent GT 0
    bp co .004 .014 n 4 p 2
    setbb SUFIX 'bp15' 
    evaluate to cut11 ( %fb15 - %nb15 ) * %disn / %ddist + %nb15 - 50
    evaluate to cut12 %cut11 + %len15 + 100
    endif
    if %fb15 LE %nb15
    setbb lent 0
    endif

  elseif $BANDP EQ 16 
    setbb lent %len16
    if %lent GT 0
    bp co .003 .013 n 4 p 2
    setbb SUFIX 'bp16' 
    evaluate to cut11 ( %fb16 - %nb16 ) * %disn / %ddist + %nb16 - 50
    evaluate to cut12 %cut11 + %len16 + 100
    endif
    if %fb16 LE %nb16
    setbb lent 0
    endif

  elseif $BANDP EQ 17 
    setbb lent %len17
    if %lent GT 0
    bp co .002 .012 n 4 p 2
    setbb SUFIX 'bp17' 
    evaluate to cut11 ( %fb17 - %nb17 ) * %disn / %ddist + %nb17 - 50
    evaluate to cut12 %cut11 + %len17 + 100
    endif
    if %fb17 LE %nb17
    setbb lent 0
    endif

  elseif $BANDP EQ 18 
    setbb lent %len18
    if %lent GT 0
    bp co .001 .011 n 4 p 2
    setbb SUFIX 'bp18' 
    evaluate to cut11 ( %fb18 - %nb18 ) * %disn / %ddist + %nb18 - 50
    evaluate to cut12 %cut11 + %len18 + 100
    endif
    if %fb18 LE %nb18
    setbb lent 0
    endif

  elseif $BANDP EQ 19 
    setbb lent %len19
    if %lent GT 0
    bp co .001 .010 n 4 p 2
    setbb SUFIX 'bp19' 
    evaluate to cut11 ( %fb19 - %nb19 ) * %disn / %ddist + %nb19 - 50
    evaluate to cut12 %cut11 + %len19 + 100
    endif
    if %fb19 LE %nb19
    setbb lent 0
    endif

  elseif $BANDP EQ 20 
    setbb lent %len20
    if %lent GT 0
    bp co .001 .009 n 4 p 2
    setbb SUFIX 'bp20' 
    evaluate to cut11 ( %fb20 - %nb20 ) * %disn / %ddist + %nb20 - 50
    evaluate to cut12 %cut11 + %len20 + 100
    endif
    if %fb20 LE %nb20
    setbb lent 0
    endif
 endif 

  if %lent GT 0
    w  tempfile
    evaluate to totlen %cut12 - %cut11 
    evaluate to tprfrac 50 / %totlen
     cut %cut11 %cut12
     r tempfile
     taper w %tprfrac
     w temp2
    cuterr fillz
    cut %ctb1 %ctb2
    r temp2
    echo on
     w "%fn1%.%SUFIX%"
    cuterr u
    echo off
  endif

 enddo
 enddo
 
