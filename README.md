# Luaroll
A way to roll several scripts into one.

## How to use
Specify modules to roll into a bundle as argument. For a module outside of the current working directory, you must specify a module name with `module=path`, otherwise module names are autodetected. Init module may be specified with `-m`, though the default is `init`

## Example
To pack luaroll, `luaroll luaroll -oluaroll.lua -mluaroll.init`