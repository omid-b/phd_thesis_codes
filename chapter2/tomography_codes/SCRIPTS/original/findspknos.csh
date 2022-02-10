rm -r spike0
mkdir spike0
cd spike0
make_reso_inC << end1
spk
9
1
end1
cp ssol ../solution
cd ..
xsc < inxc
plca-synth.gmt
mv *.ps spike0
rm solution d*
gv spike0/plca_synth.ps
