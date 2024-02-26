#!/bin/sh
clang -lm -Ofast -march=native -flto=thin scripts/easu.c -o scripts/easu &&
glslc -O -fshader-stage=compute scripts/easu.glsl -o scripts/easu.spv 
