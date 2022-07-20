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

table.insert(package.searchers, 1, function(pkg)
    if not roll[pkg] then return string.format("no field roll[\"%s\"]", pkg) end
    return load(lzss_decompress(roll[pkg]), roll_files[pkg])
end)

local cache = {}
local function irequire(pkg)
    if cache[pkg] then return cache[pkg] end
    if not roll[pkg] then return require(pkg) end
    local et = setmetatable({
        require = irequire
    }, {__index=_G})
    et._G = et
    return load(lzss_decompress(roll[pkg]), roll_files[pkg], "t", et)
end