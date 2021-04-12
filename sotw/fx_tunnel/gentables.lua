#!/usr/bin/env lua

function precalc(w, h, sz, tiling)
    local d,a = {},{}
    for y=0,h-1 do
        for x=0,w-1 do
            local xx, yy = x-w/2, y-h/2
            d[#d+1] = math.modf(math.fmod(tiling * sz / (1+math.sqrt(xx*xx + yy*yy)), sz))
            a[#a+1] = math.modf(0.5 * (sz-1) * (1 + math.atan2(yy, xx) / math.pi))
        end
    end
    return d,a
end

function sintab(max)
    local s = {}
    max = max * 0.5
    for i=1,256 do
        s[i] = max * (1 + math.sin(2*math.pi * (i-1)/256))
    end
    return s
end

function asCtable(t, name, signed, sz, fmt)
    local countperline = { [1] = 16, [2] = 12, [4] = 16 }
    local cl = countperline[sz]
    local s = { table.concat{signed and 's' or 'u', 8*sz, ' ', name, '[] =', '\n{'} }
    local c = #t
    local i = 1
    for l=1,c/cl do
        local ls = { [cl+1] = '' }
        for v=1,cl do ls[v] = fmt(t[i]) i=i+1 end
        s[#s+1] = table.concat(ls, ',')
    end
    local lastls = {}
    while i <= c do lastls[#lastls+1] = t[i] i=i+1 end
    if #lastls > 0 then s[#s+1] = table.concat(lastls, ',') end
    s[#s+1] = '};\n\n'
    return table.concat(s, '\n')
end

function asBin(t)
    return string.char(table.unpack(t))
end

--[[
local output = "source/tunnel_data.h"
local f = io.open(output, 'w')
f:write(asCtable(d, 'fxtn_d', false, 1, function(d) return string.format('0x%02X', d) end))
f:write(asCtable(a, 'fxtn_a', true, 1, function(d) return string.format('%4d', d) end))
--]]

local screenWidth, screenHeight, texSize = 240*2, 160*2, 256
local d, a = precalc(screenWidth, screenHeight, texSize, 32)

local f
f = io.open('data/fxtn_d.bin', 'wb')
f:write(asBin(d))
f:close()
f = io.open('data/fxtn_a.bin', 'wb')
f:write(asBin(a))
f:close()

f = io.open('data/fxtn_sin.bin', 'wb')
f:write(asBin(sintab(255)))
f:close()
