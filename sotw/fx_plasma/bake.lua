#!/usr/bin/env lua

local dist = function(x, y)
    x = x - 80
    y = y - 20
    return math.modf(math.sqrt(x*x+y*y))
end

local sin = function(v)
    local max = 255 * 0.5
    return max * (1 + math.sin(2*math.pi * v/256))
end

local plasma = function(x, y)
    return bit32.band((sin(x * 4) + sin(y * 2) + sin((x+y)*8) + dist(x, y) * 32) / 4, 255)
end

local pixelf = function(w, h, f)
    local t = {}
    for y=0,h-1 do
        for x=0,w-1 do
            t[#t+1] = f(x,y)
        end
    end
    return t
end

function asBin(t)
    return string.char(table.unpack(t))
end

f = io.open('data/plasma.bin', 'wb')
f:write(asBin(pixelf(240, 160, plasma)))
f:close()
