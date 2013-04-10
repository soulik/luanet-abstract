#!/bin/sh

export PATH="./lib:$PATH"
MACHINE=`uname -a`

if echo "$MACHINE" | grep -qi "arm" ; then
    ./lib/external/platform-specific/Linux/arm/luajit ./lib/main.lua
else
    if echo "$MACHINE" | grep -qi "x64" ; then
	./lib/external/platform-specific/Linux/x64/luajit ./lib/main.lua
    else
	if echo "$MACHINE" | grep -qi "x86" ; then
	    ./lib/external/platform-specific/Linux/x86/luajit ./lib/main.lua
	else
	    echo "You are using unsupported platform!"
	fi
    fi
fi
