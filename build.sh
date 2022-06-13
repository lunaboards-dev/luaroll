#!/bin/bash
ARGPARSE=$(lua -e "print(select(2, require('argparse')))")
# rm -rf build
mkdir -p build
echo "#!/usr/bin/env lua" > build/luaroll
lua luaroll/init.lua -o- -m"luaroll.init" "argparse=$ARGPARSE" luaroll >> build/luaroll