#!/bin/sh
if [ $# -eq 0 ]; then
	clang -lm -Ofast -march=native -flto=thin scripts/fsr.c -o scripts/fsr || exit -1
fi
glslc $@ -O -fshader-stage=compute scripts/fsr.glsl -o scripts/fsr.spv || exit -1
