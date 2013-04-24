#!/bin/sh

export PATH="./lib:$PATH"
MACHINE=`uname -a`
LUAJIT="./lib/external/platform-specific/Linux/x86/luajit"
PARAM="./lib/main.lua"

if echo "$MACHINE" | grep -qi "arm" ; then
    LUAJIT="./lib/external/platform-specific/Linux/arm/luajit"
else
    if echo "$MACHINE" | grep -qi "x86_64" ; then
	LUAJIT="./lib/external/platform-specific/Linux/x64/luajit"
    else
	if echo "$MACHINE" | grep -qi "x86" ; then
	    LUAJIT="./lib/external/platform-specific/Linux/x86/luajit"
	else
	    echo "You are using unsupported platform!"
	    exit
	fi
    fi
fi

if [ -f $LUAJIT ]; then
    $LUAJIT $PARAM
else
    echo "File not found: $LUAJIT !"
fi
