#!/bin/csh
# Outputs: 1. Number of stations for each event (TPW_numST.txt).
#          2.number of OK bandpasses for each bp (TPW_numBP.txt).

cd `dirname $0`
source ../param.csh

clear
cd $homedir
if (-e events.tmp) rm -f *.tmp
if (-e TPW_numStation.txt) rm -f TPW_numStation.txt
ls| grep "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"> events.tmp
set numEvt = `cat events.tmp|wc -l`
echo "Number of events: $numEvt"

foreach evt (`cat events.tmp`) 
  cd $evt
  set numSt = `ls *bp??|awk -F. '{print $1}'|sort|uniq|wc -l`
  echo "$evt $numSt" >> ../TPW_numStation.tmp
  cd $homedir
end


echo "bp01 `ls */*bp01|wc -l` of `ls */*bp01*|wc -l`" >> TPW_numBP.tmp
echo "bp02 `ls */*bp02|wc -l` of `ls */*bp02*|wc -l`" >> TPW_numBP.tmp
echo "bp03 `ls */*bp03|wc -l` of `ls */*bp03*|wc -l`" >> TPW_numBP.tmp
echo "bp04 `ls */*bp04|wc -l` of `ls */*bp04*|wc -l`" >> TPW_numBP.tmp
echo "bp05 `ls */*bp05|wc -l` of `ls */*bp05*|wc -l`" >> TPW_numBP.tmp
echo "bp06 `ls */*bp06|wc -l` of `ls */*bp06*|wc -l`" >> TPW_numBP.tmp
echo "bp07 `ls */*bp07|wc -l` of `ls */*bp07*|wc -l`" >> TPW_numBP.tmp
echo "bp08 `ls */*bp08|wc -l` of `ls */*bp08*|wc -l`" >> TPW_numBP.tmp
echo "bp09 `ls */*bp09|wc -l` of `ls */*bp09*|wc -l`" >> TPW_numBP.tmp
echo "bp10 `ls */*bp10|wc -l` of `ls */*bp10*|wc -l`" >> TPW_numBP.tmp
echo "bp11 `ls */*bp11|wc -l` of `ls */*bp11*|wc -l`" >> TPW_numBP.tmp
echo "bp12 `ls */*bp12|wc -l` of `ls */*bp12*|wc -l`" >> TPW_numBP.tmp
echo "bp13 `ls */*bp13|wc -l` of `ls */*bp13*|wc -l`" >> TPW_numBP.tmp
echo "bp14 `ls */*bp14|wc -l` of `ls */*bp14*|wc -l`" >> TPW_numBP.tmp
echo "bp15 `ls */*bp15|wc -l` of `ls */*bp15*|wc -l`" >> TPW_numBP.tmp
echo "bp16 `ls */*bp16|wc -l` of `ls */*bp16*|wc -l`" >> TPW_numBP.tmp
echo "bp17 `ls */*bp17|wc -l` of `ls */*bp17*|wc -l`" >> TPW_numBP.tmp
echo "bp18 `ls */*bp18|wc -l` of `ls */*bp18*|wc -l`" >> TPW_numBP.tmp
echo "bp19 `ls */*bp19|wc -l` of `ls */*bp19*|wc -l`" >> TPW_numBP.tmp
echo "bp20 `ls */*bp20|wc -l` of `ls */*bp20*|wc -l`" >> TPW_numBP.tmp

sort -nk2 TPW_numStation.tmp> TPW_numSt.tmp
sort -nk2 TPW_numBP.tmp > TPW_numBPsort.tmp

mv  TPW_numSt.tmp TPW_numST.txt
mv  TPW_numBPsort.tmp TPW_numBP.txt
rm -f *.tmp
