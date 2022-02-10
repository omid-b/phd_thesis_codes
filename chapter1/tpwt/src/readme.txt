Note: please contact the code owners to access the source codes.

gfortran -o createsac createsac.f /usr/local/sac/lib/libsacio.a
gfortran -o creatgridnode creatgridnode.f
gfortran -o getdatafromsac getdatafromsac.f /usr/local/sac/lib/libsacio.a
gfortran -o gridgenvar gridgenvar.yang_v2.f
gfortran -o orderfilelist orderfilelist.f
gfortran -o pstdper pstdper.f
gfortran -o pvelper pvelper.f
gfortran -o qcfilelist qcfilelist.f
gfortran -o rdsetupsimul rdsetupsimul.yang.f /usr/local/sac/lib/libsacio.a
gfortran -o sensitivity sensitivity.f
gfortran -o sortdis sortdis.f
gfortran -o sim360kern simannerr360.kern.f anneal.f ran1.f
gfortran -o sim60kern simannerr60.kern.f anneal.f ran1.f

