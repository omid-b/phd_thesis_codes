#!/bin/csh -f

set refd = '/data/home/darbyshire_f/SW_TOMOGRAPHY/GREENLAND'
set ps = `ls | grep ^"shell_key" | cut -c 10-12`
echo $ps
foreach p ($ps)
  mkdir $p
  echo $p
  set fs = `ls | grep {$p}$ | grep ^"[a-z]"`
  foreach f ($fs)
    set f1 = `echo $f | sed s/$p/""/g`
    cp $f $p/$f1
  end
  cp $refd/iniac-master $p/iniac
  cp $refd/inxc-master $p/inxc
end

rm colsums* ers* matrix* path* rhs* shell* stations* tri*
