#!/usr/bin/env lua

function bytes16(x)
    return string.char(x&0xFF,(x>>8)&0xFF)
end

local f,e = io.open("../data/twister_div.bin", "wb")
if f == nil then print(e) os.exit(false) end
for i=1,64 do f:write(bytes16(math.floor((64/i) * 256 + .5))) end
f:close()
