#!/bin/sh
if [ "$#" -lt 2 ]; then
	echo 'proc.sh <128-split> <use-rcas>'
	exit
elif [ "$2" -eq 0 ]; then
	folder='easu'
elif [ "$2" -eq 1 ]; then
	folder='rcas'
fi
mkdir -p models
mkdir -p test
mkdir in &&
cp -r $1 in/128 &&
mkdir in/64 && mogrify -colorspace Gray -path in/64 -filter Hermite -resize 50% -format jpg -quality 75 in/128/* &&
mkdir in/$folder && parallel "f=\$(basename {}); echo \$f; ./scripts/fsr {} in/$folder/\$f $2" ::: in/64/*
