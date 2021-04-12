#!/usr/bin/env lua

local n = arg[1]
local lo,hi = "",""
local x = -1
for i=n,1,-1 do
    local v
    repeat
        x = x+1
        v = n / (1 + x / (2^8))
    until math.floor(v) == i
    local s = (n-i+1)%16 == 0 and "\n" or " "
    lo = lo .. string.format("0x%02X%s", x&0xFF, s)
    hi = hi .. string.format("0x%02X%s", 1+(x>>8), s)
end
io.write(hi, "\n\n", lo)
