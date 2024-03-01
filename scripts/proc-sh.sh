#!/bin/sh
if [ "$#" -lt 2 ]; then
	echo 'proc.sh <128-split> <use-rcas>'
	exit -1
elif [ $2 -eq 0 ]; then
	folder='easu'
elif [ $2 -eq 1 ]; then
	sharpness=2.0
	./scripts/build.sh -DSHARPNESS=$sharpness || exit
	folder="rcas-$sharpness"
elif [ $2 -ne -1 ]; then
	echo 'proc.sh <128-split> <use-rcas>'
	exit -1
fi
./scripts/mkfolders.sh
mkdir in &&
cp -r $1 in/128 &&
mkdir in/64 && mogrify -colorspace Gray -path in/64 -filter Hermite -resize 50% in/128/* &&
if [[ $2 -ne -1 ]]; then
	mkdir in/$folder && parallel "f=\$(basename {}); echo \$f; ./scripts/fsr {} in/$folder/\$f $2" ::: in/64/*
fi
