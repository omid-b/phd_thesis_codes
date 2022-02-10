#!/bin/csh -f

#set ds = `ls -F | grep "[0-9][0-9][0-9]/"`
#foreach d ($ds)
#foreach d (0?0 0?5)

#foreach d (spike1 spike1anis spike2 spike2anis spike3 spike3anis spike4 spike4anis spike5 spike5anis spike6 spike6anis)
#foreach d (2psi_only 4psi_only anisrev isotropic)

foreach d (01? 02? 03? 04? 05? 06? 07? 08?)

#  echo "0" > $d/inxc
#  echo "0" >> $d/inxc
#  echo "200. 200. 200." >> $d/inxc
#  echo "1 0.2" >> $d/inxc
#  echo "1 0.7" >> $d/inxc
  cd $d
#  xsc < inxc > outxc
#  plcg-rob-ant.gmt
/data/home/darbyshire_f/SW_TOMOGRAPHY/SCRIPTS/plcg-greenland-new.gmt
  cd ..
end

