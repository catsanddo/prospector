@echo off

if NOT EXIST bin mkdir bin

odin build . -out:bin\prospector.exe
