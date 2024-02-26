#!/bin/sh
mkdir -p models
mkdir -p test
mkdir in &&
mkdir in/128; parallel 'convert {} -format png -colorspace Gray -gravity NorthWest -chop $(convert {} -format "%[fx:w%128]x%[fx:h%128]" info:) +repage -crop 128x128 +repage +adjoin in/128/{#}_%d.png' ::: $1/* &&
mkdir in/64 && mogrify -colorspace Gray -path in/64 -filter Box -resize 50% in/128/* &&
mkdir in/fsr && parallel 'f=$(basename {}); echo $f; ./scripts/easu {} in/fsr/$f' ::: in/64/*
