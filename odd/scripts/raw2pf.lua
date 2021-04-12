#!/usr/bin/env lua

if #arg ~= 1 then
    print('raw2pf - convert RGB raw images to playfield data')
    print('usage: raw2pf img.raw')
    os.exit(true)
end

local f = assert(io.open(arg[1], "rb"))
local d = {}
local yc = 1
local run = true
while true do
    local l = {}
    for x=1,40 do
        local c = f:read(3)
        if not c then run = false break end
        l[x] = c == "\xff\xff\xff" and 0 or 1
    end
    if not run then break end
    --for k,v in ipairs(l) do io.write(v) end
    --io.write("\n")
    d[yc] = l
    yc = yc + 1
end
f:close()
yc = #d

local pf = function(o)
    local w = io.write
    -- pf0
    w('\tdc.b ')
    for y=yc,1,-1 do
        local v=0 for x=1,4 do v = v | (d[y][x+o] << 3+x) end
        if y ~= yc then w(',') end
        w(string.format('$%02X', v))
    end
    w('\n')
    -- pf1
    w('\tdc.b ')
    for y=yc,1,-1 do
        local v=0 for x=5,12 do v = v | (d[y][x+o] << 12-x) end
        if y ~= yc then w(',') end
        w(string.format('$%02X', v))
    end
    w('\n')
    -- pf2
    w('\tdc.b ')
    for y=yc,1,-1 do
        local v=0 for x=13,20 do v = v | (d[y][x+o] << x-13) end
        if y ~= yc then w(',') end
        w(string.format('$%02X', v))
    end
    w('\n')
end

pf(0)
pf(20)
