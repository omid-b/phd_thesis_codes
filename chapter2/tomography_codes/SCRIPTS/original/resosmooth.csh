#!/bin/csh -f

echo 'Enter smoothness parameters (3 numbers separated by spaces)'
set smth=($<)
#echo 'Enter grad-damp parameters (3 numbers separated by spaces)'
#set gdamp=($<)

echo 'Re-enter parameters (3 numbers separated by "_")'
#echo 'Enter directory name'
set testdir=($<)

mkdir $testdir
cd $testdir
#make_reso_inC << end1
#spk
#5
#end1
make_reso_inC_fd << end1
spkanis
6
end1
cp ssol ../solution
#make_rhsC
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..

  echo "1000" > iniac
  echo "25" >> iniac
  echo "1 2 3 5 7 10 15 20 30 40 50 70 100 130 160 200 250 300 350 400 500 600 700 800 900" >> iniac
  echo "0.05 0.05 0.05" >> iniac
  echo $smth >> iniac
#  echo "0.5 1 1" >> iniac
#  echo $gdamp >> iniac
  echo "0.2 0.4 0.4" >> iniac
  echo "0 0 0" >> iniac
  echo "0.6 0.6 0.6" >> iniac

iac < iniac > outiac
xsc < inxc > outxc
plcg-greenland.gmt
mv d* rhs solution* *.ps $testdir
cp iniac inxc matrix* path* shell* stations outiac $testdir
