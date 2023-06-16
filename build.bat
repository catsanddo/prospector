@echo off

if NOT EXIST bin mkdir bin

if "%1"=="-t" goto TEST

odin build . -out:bin\prospector.exe -debug

if ERRORLEVEL 1 goto END

if "%1"=="-r" bin\prospector.exe
goto END

:TEST
odin test . -out:bin\prospector.exe

:END
