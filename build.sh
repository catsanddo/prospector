#!/bin/sh

mkdir -p bin

gcc src/prospect.c -o bin/prospector -g -Iinclude -lraylib
