#!/usr/bin/env lua

local lo,hi = "",""
for y=0,174 do
    local v = 1 / (1 - math.abs(math.sin(math.pi * ((y+.5)/175 - .5))))
    local s,e = y%16 == 0 and "    " or "", (y+1)%16 == 0 and "\n" or " "
    if (v > 255) then v = 255.999 end
    lo = lo .. string.format("%s0x%02X%s", s, math.floor(v*256+.5)&0xFF, e)
    hi = hi .. string.format("%s0x%02X%s", s, math.floor(v)&0xFF, e)
end
io.write("data gfx_inctab_hi {\n", hi,
         "\n}\ndata gfx_inctab_lo {\n", lo, "\n}")
