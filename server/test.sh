#!/bin/sh

export PATH="./lib:$PATH"
MACHINE=`uname -m`

if echo "$MACHINE" | grep -qi "arm" ; then
    ./lib/external/platform-specific/Linux/arm/luajit ./lib/test.lua $1
else
    if echo "$MACHINE" | grep -qi "x64" ; then
	./lib/external/platform-specific/Linux/x64/luajit ./lib/test.lua $1
    else
	./lib/external/platform-specific/Linux/x86/luajit ./lib/test.lua $1
    fi
fi
