#!/bin/csh -f

# USAGE: resotests-new.csh PERIOD

# Resolution choices:
# 1 isotropic only
# 2 2psi only
# 3 4psi only
# 4 constant
# 5 grad_nw_se
# 6 grad_ne_sw
# 7 grad_ns
# 8 grad_ew
# 9 spike 1
# 10 spike 2
# 11 spike 3
# 12 spike 4
# 13 spike 1 anis
# 14 spike 2 anis
# 15 spike 3 anis
# 16 spike 4 anis
# 17 anisrev
# 18 spike 5
# 19 spike 6
# 20 spike 5 anis
# 21 spike 6 anis

set homedir=/data/home/darbyshire_f/SW_TOMOGRAPHY

set dirvalues = $1
#foreach reschoice(1 2 3 9 10 11 12 13 14 15 16 17 18 19 20 21)
foreach reschoice(13)
#foreach reschoice(9 10 11 12 13 14 15 16 18 19 20 21)
#foreach reschoice (1 2 3 17)

foreach dirct ($homedir/GREENLAND/$dirvalues)
 
cd $dirct

if (! -d initial) then
mkdir initial
mv d* rhs solution* *.ps initial
cp iniac inxc matrix* path* shell* stations initial
endif

if ($reschoice == 1) then
set testdir=isotropic 
mkdir $testdir
cp initial/solution $testdir
cd $testdir
make_reso_inC << end1
orig
0
end1
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 2) then
set testdir=2psi_only
mkdir $testdir
cp initial/solution $testdir
cd $testdir
make_reso_inC << end1
orig
1
end1
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 3) then
set testdir=4psi_only
mkdir $testdir
cp initial/solution $testdir
cd $testdir
make_reso_inC << end1
orig
2
end1
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif
 
if ($reschoice == 4) then
set testdir=constant
mkdir $testdir
cd $testdir
make_reso_inC << end1
const
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 5) then
set testdir=grad_nw_se 
mkdir $testdir
cd $testdir
make_reso_inC << end1
grad
-45
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif
 
if ($reschoice == 6) then
set testdir=grad_ne_sw
mkdir $testdir
cd $testdir
make_reso_inC << end1
grad
45
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif
 
if ($reschoice == 7) then
set testdir=grad_ns
mkdir $testdir
cd $testdir
make_reso_inC << end1
grad
90
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif
 
if ($reschoice == 8) then
set testdir=grad_ew
mkdir $testdir
cd $testdir
make_reso_inC << end1
grad
180
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif
 
if ($reschoice == 9) then
set testdir=spike1
mkdir $testdir
cp ../spk1 $testdir
cd $testdir
make_reso_inC << end1
spk
1
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 10) then
set testdir=spike2
mkdir $testdir
cp ../spk2 $testdir
cp ../cea_tomo_L.cpt $testdir
cd $testdir
make_reso_inC << end1
spk
2
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 11) then
set testdir=spike3 
mkdir $testdir
cp ../spk3 $testdir
cp ../cea_tomo_L.cpt $testdir
cd $testdir
make_reso_inC << end1
spk
3
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 12) then
set testdir=spike4
mkdir $testdir
cp ../spk4 $testdir
cp ../cea_tomo_L.cpt $testdir
cd $testdir
make_reso_inC << end1
spk
4
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 13) then
set testdir=spike1anis
mkdir $testdir
cp ../spk1 $testdir
cd $testdir
make_reso_inC << end1
spkanis
1
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 14) then
set testdir=spike2anis
mkdir $testdir
cp ../spk2 $testdir
cd $testdir
make_reso_inC << end1
spkanis
2
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 15) then
set testdir=spike3anis
mkdir $testdir
cp ../spk3 $testdir
cd $testdir
make_reso_inC << end1
spkanis
3
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 16) then
set testdir=spike4anis
mkdir $testdir
cp ../spk4 $testdir
cd $testdir
make_reso_inC << end1
spkanis
4
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 17) then
set testdir=anisrev
mkdir $testdir
cp initial/solution $testdir
cd $testdir
make_reso_inC << end1
anisrev
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 18) then
set testdir=spike5
mkdir $testdir
cp ../spk5 $testdir
cd $testdir
make_reso_inC << end1
spk
5
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 19) then
set testdir=spike6
mkdir $testdir
cp ../spk6 $testdir
cd $testdir
make_reso_inC << end1
spk
6
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 20) then
set testdir=spike5anis
mkdir $testdir
cp ../spk5 $testdir
cd $testdir
make_reso_inC << end1
spkanis
5
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif

if ($reschoice == 21) then
set testdir=spike6anis
mkdir $testdir
cp ../spk6 $testdir
cd $testdir
make_reso_inC << end1
spkanis
6
end1
cp ssol ../solution
cd ..
xsc < inxc
$homedir/SCRIPTS/plcg-synth-new.gmt
mv *.ps $testdir
rm solution d*
cd $testdir
make_rhsC_err << end2
0.02
end2
cp srhs ../rhs
cd ..
iac < iniac > outiac
xsc < inxc > outxc
$homedir/SCRIPTS/plcg-greenland-new.gmt
csh $homedir/SCRIPTS/getstats.csh
mv d* rhs solution* *.ps stats-info $testdir
cp iniac inxc outiac outxc matrix* path* shell* stations $testdir
endif


cd $homedir

end
end
