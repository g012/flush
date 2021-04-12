#!/usr/bin/env lua

function rgb(r,g,b)
    local sr,sl = bit32.rshift, bit32.lshift
    local c = bit32.bor(sr(r,3), sl(sr(g,3),5), sl(sr(b,3),10))
    return bit32.band(c,255), sr(c,8)
end

function readPalette(f)
    local t = {}
    for line in io.lines(f) do
        local r,g,b = line:match('#(%x%x)(%x%x)(%x%x)')
        local lo,hi = rgb(tonumber(r,16), tonumber(g,16), tonumber(b,16))
        t[#t+1]=lo t[#t+1]=hi
    end
    return t
end

function dist(w, h, cx, cy, max)
    local d = {}
    for y=0,h-1 do
        for x=0,w-1 do
            local xx, yy = x-cx, y-cy
            d[#d+1] = math.modf(255 * math.sqrt(xx*xx + yy*yy) / max)
        end
    end
    return d
end

function asBin(t)
    return string.char(table.unpack(t))
end

f = io.open('data/fxpl_dist.bin', 'wb')
f:write(asBin(dist(240, 160, 80, 20, 255)))
f:close()

for i=1,4 do
    f = io.open('data/fxpl_pal' .. i .. '.bin', 'wb')
    f:write(asBin(readPalette('palette' .. i .. '.txt')))
    f:close()
end
