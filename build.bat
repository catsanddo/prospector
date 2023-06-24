@echo off

if NOT EXIST bin mkdir bin

if "%1"=="-t" goto TEST
if "%1"=="-h" goto HELP

odin build . -out:bin\prospector.exe -debug

if ERRORLEVEL 1 goto END

if "%1"=="-r" bin\prospector.exe

goto END
:TEST
odin test . -out:bin\prospector.exe

goto END
:HELP
echo Usage: %0 [option]
echo Options
echo   -h    Display this help text
echo   -r    Run the program after compiling
echo   -t    Run odin test on the project
echo Due to batch script limitations (and laziness)
echo only one option can be specified at a time

:END
