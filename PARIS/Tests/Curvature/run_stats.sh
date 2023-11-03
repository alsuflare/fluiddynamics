#! /bin/bash
#set -x

if [ $# -lt 5 ]; then
    echo "missing arguments"
    echo usage $0 nx init radius nstats dim
    exit
fi

nx=$1
init=$2
radius=$3
ny=$nx; nz=$nx
nstats=$4
d=$5

RANDOM=$$
ndepth=`head -60  ../../surface_tension.f90 |  awk -F '=' ' /NDEPTH/ {print $2}' | tr -d ' '`
dim=$d'D'

/bin/rm -rf errors.tmp

for i in $(seq 1 $nstats); 
do 
    echo -n "."
    xc=`awk -v nx=$nx -v random=$RANDOM 'BEGIN {print (0.5 + 0.5*(random / nx)/32767)}'`
    yc=`awk -v nx=$nx -v random=$RANDOM 'BEGIN {print (0.5 + 0.5*(random / nx)/32767)}'`
    zc=`awk -v nx=$nx -v random=$RANDOM 'BEGIN {print (0.5 + 0.5*(random / nx)/32767)}'`
    echo "xc=$xc; yc=$yc; zc=$zc" > center_coordinates.txt
    ./run_one_test.sh F Curvature_test F 3 $radius 1e20 $init $nx $xc $yc $zc $d || exit 1
    
    if [ -d out ]; then
	cd out
	echo `awk -v nx=$nx -v radius=$radius 'BEGIN {print nx * radius }'`  `pariscompare curvature.txt reference.txt 0.1 1 2 `  >> ../errors.tmp
	cd ..
	awk -v nx=$nx  -v radius=$radius '{print nx * radius, $1, $2, $3 }' mcount.tmp >> method_count-$dim-$ndepth.tmp
    fi
done
echo " "

cat errors.tmp | awk 'BEGIN {err=0.; a=0.} { if ($3 > err) {err = $3}; a = a +$2}; END {print $1, a/NR,  err, NR}' 
cat errors.tmp | awk 'BEGIN {err=0.; a=0.} { if ($3 > err) {err = $3}; a = a +$2}; END {print $1, a/NR,  err}'  >> paris-$dim-$ndepth.tmp

exit 0
