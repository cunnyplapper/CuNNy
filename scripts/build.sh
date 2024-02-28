#!/bin/sh
clang -lm -Ofast -march=native -flto=thin scripts/fsr.c -o scripts/fsr &&
glslc -O -fshader-stage=compute scripts/fsr.glsl -o scripts/fsr.spv 
