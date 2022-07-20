local lzss = require("luaroll.lzss")
local argparse = require("argparse")
local lfs = require("lfs")
local main = [=[
local function lzss_decompress(a)local b,c,d,e,j,i,h,g=1,'',''while b<=#a do
e=c.byte(a,b)b=b+1
for k=0,7 do h=c.sub
g=h(a,b,b)if e>>k&1<1 and b<#a then
i=c.unpack('>I2',a,b)j=1+(i>>4)g=h(d,j,j+(i&15)+2)b=b+1
end
b=b+1
c=c..g
d=h(d..g,-4^6)end
end
return c end
]=]
local searcher = [=[
table.insert(package.searchers, 1, function(pkg)
if not roll[pkg] then return string.format("no field roll[\"%s\"]", pkg) end
return load(lzss_decompress(roll_files[roll[pkg]]), roll[pkg])
end)
]=]
local overwrite = [=[
local cache = {}
local global
local larg
if not arg then larg = table.pack(...) end
local function irequire(pkg)
if cache[pkg] then return cache[pkg] end
if not roll[pkg] then return require(pkg) end
if not global then
global = setmetatable({
    require = irequire,
    arg = larg
}, {__index=_G})
global._G = global
end
local rv = load(lzss_decompress(roll_files[roll[pkg]]), roll[pkg], "t", global)()
cache[pkg] = rv
return rv
end
]=]

assert(lzss.decompress(lzss.compress(main)) == main, "Internal compressor error")

--[[local function tostr(str)
    local num_equals = 0
    str:gsub("]=*]", function(match)
        if #match-2 >= num_equals then
            num_equals = #match-1
        end
        return match
    end)
    local eq = string.rep("=", num_equals)
    --return string.format("[%s[%s]%s]", eq, str, eq)
    return "["..eq.."["..str.."]"..eq.."]"
end]]
local function tostr(str)
    return "\""..str:gsub("\\", "\\\\"):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\"", "\\\"").."\""
end

assert(lzss.decompress(load("return "..tostr(lzss.compress(main)))()) == main, "sanity check failed")

local parser = argparse("luaroll", "LuaRoll", "Rolls several scripts into a single one.")
parser:option("-m --main", "Sets the path that gets loaded initially."):default("init")
parser:option("-o --output", "Output file"):default("roll.lua")
parser:flag("-r --overwrite-require", "Overwrites the require function instead of adding a searcher.")
parser:argument("files", "A file or directory to add."):args "+"
local args = parser:parse()

local of
if args.output == "-" then
    of = io.stdout
else
    of = assert(io.open(args.output, "wb"))
end

local files = {}
local packages = {}

local function die(msg)
    io.stderr:write("error: ", msg, "\n")
    os.exit(1)
end

local function add_package(basepkg, path)
    io.stderr:write(string.format("%s = %s\n", basepkg, path))
    if lfs.attributes(path, "mode") == "directory" then
        local subdir = {}
        for ent in lfs.dir(path) do
            local epath = path.."/"..ent
            --io.stderr:write(, "\n")
            if lfs.attributes(epath, "mode") == "file" and ent:sub(#ent-3) == ".lua" then
                local pkg_name = ent:sub(1, #ent-4)
                --table.insert(subdir, pkg_name)
                subdir[pkg_name] = true
                add_package(basepkg.."."..pkg_name, epath)
            elseif lfs.attributes(epath, "mode") == "directory" and ent:sub(1,1) ~= "." then
                add_package(basepkg.."."..ent, epath)
            end
        end
        if subdir["init"] and not packages[basepkg] then
            packages[basepkg] = packages[basepkg..".init"]
        end
    elseif lfs.attributes(path, "mode") == "file" then
        local f = assert(io.open(path, "rb"))
        local d = f:read("*a")
        f:close()
        files["="..path] = lzss.compress(d)
        packages[basepkg] = "="..path
    else
        die(string.format("package not a file or directory (%s)", path))
    end
end

for i=1, #args.files do
    local f = args.files[i]
    local k, v = f:match("([^=]+)=([^=]+)")
    if not k and f:match("/") then
        die("cannot add files outside of current directory without specifying a package name")
    elseif not k then
        k = f:gsub("%.lua", "")
        v = f
    end
    add_package(k, v)
end

of:write("local roll_files = {\n")
for k, v in pairs(files) do
    of:write(string.format("\t[%q] = %s,\n", k, tostr(v)))
    --of:write(string.format("\t[%q] = %q,\n", k, v))
end
of:write("}\nlocal roll = {\n")
for k, v in pairs(packages) do
    of:write(string.format("\t[%q] = %q,\n", k, v))
end
of:write("}\n")
of:write(main)
if args.overwrite_require then
    of:write(overwrite)
    of:write(string.format("return irequire(%q)\n", args.main))
else
    of:write(searcher)
    of:write(string.format("return require(%q)\n", args.main))
end