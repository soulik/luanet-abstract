@echo off
set PATH=.\lib;%PATH%
.\lib\external\luajit .\lib\test.lua %1