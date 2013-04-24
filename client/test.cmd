@echo off
set PATH=.\lib;%PATH%
.\lib\external\platform-specific\Windows\x86\luajit.exe .\lib\test.lua %1