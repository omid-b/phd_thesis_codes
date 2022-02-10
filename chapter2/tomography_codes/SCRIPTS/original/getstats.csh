#!/bin/csh -f

echo "Inversion Statistics" > stats-info

grep ^"[nlig ][oatr 0-9][rtea 0-9][merd0-9]" outiac > tmp
  grep iso tmp | head -1 >> stats-info
  grep iso tmp | head -2 | tail -1 >> stats-info
  grep iso tmp | tail -1 >> stats-info

  set numiter = `tail -1 tmp | awk '{print $1}' `
  set remvar =  `tail -1 tmp | awk '{print $7}' `
  echo "Number of iterations, remaining variance: $numiter $remvar"  >> stats-info
  echo "" >> stats-info

grep ^"[m ][ai]" outxc > tmp1
  head -1 tmp1 >> stats-info
  head -2 tmp1 | tail -1 >> stats-info
  set slim = `head -3 inxc | tail -1 | awk '{print $1}' `
  echo "(saturated-scale limits are "$slim" of the max)" >> stats-info
  head -3 tmp1 | tail -1 >> stats-info
  head -4 tmp1 | tail -1 >> stats-info
  head -5 tmp1 | tail -1 >> stats-info
  head -6 tmp1 | tail -1 >> stats-info
  
  grep "roughness" outiac >> stats-info
  grep "average phase velocity" outiac >> stats-info
  
  set period = `pwd | awk -F/ '{print $NF}' `

  echo "period: "$period" s" >> stats-info
  set np = `grep ^">" paths | wc -l`
  echo "number of paths: "$np >> stats-info
  set ks = `head -1 shell`
  set ks = `echo $ks[3] | awk -F. '{print $1}'`
  echo "knot spacing: "$ks" km" >> stats-info
