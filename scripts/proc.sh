#!/bin/sh
if [ "$#" -lt 2 ]; then
	echo 'proc.sh <in-folder> <use-rcas>'
	exit
elif [ "$2" -eq 0 ]; then
	folder='easu'
elif [ "$2" -eq 1 ]; then
	folder='rcas'
fi
mkdir -p models
mkdir -p test
mkdir in &&
mkdir in/128; parallel 'convert {} -format png -colorspace Gray -gravity NorthWest -chop $(convert {} -format "%[fx:w%128]x%[fx:h%128]" info:) +repage -crop 128x128 +repage +adjoin in/128/{#}_%d.png' ::: $1/* &&
mkdir in/64 && mogrify -colorspace Gray -path in/64 -filter Box -resize 50% in/128/* &&
mkdir in/$folder && parallel "f=\$(basename {}); echo \$f; ./scripts/fsr {} in/$folder/\$f $2" ::: in/64/*
