#!/usr/bin/env lua
-- requires Lua 5.3 (bitwise operators)

local ramps = { { 0x652F00, 0xEF913E }, { 0x3A8100, 0xA3E86A }, { 0x0D3080, 0x7C98D8 }, { 0x870D52, 0xE48FBF } }

require("color")

function bytes16(x)
    local b2=x%256  x=(x-x%256)/256
    local b1=x%256  x=(x-x%256)/256
    return string.char(b2,b1)
end

function gen_ramp(col0, col1, step_count)
    -- keep color 0 at black
    local v = { { r = 0, g = 0, b = 0 } }
    local r0 = col0 & 0xFF
    local g0 = (col0 >> 8) & 0xFF
    local b0 = (col0 >> 16) & 0xFF
    local r1 = col1 & 0xFF
    local g1 = (col1 >> 8) & 0xFF
    local b1 = (col1 >> 16) & 0xFF
    local h0, s0, l0 = rgbToHsl(r0, g0, b0)
    local h1, s1, l1 = rgbToHsl(r1, g1, b1)
    local sc = step_count - 2
    for i=0,sc do
        local c = {}
        local h = h0 + i * (h1 - h0) / sc
        local s = s0 + i * (s1 - s0) / sc
        local l = l0 + i * (l1 - l0) / sc
        c.r, c.g, c.b = hslToRgb(h, s, l)
        table.insert(v, c)
    end
    return v
end

local f,e = io.open("../data/twister_pal.bin", "wb")
if f == nil then print(e) os.exit(false) end
for _,v in ipairs(ramps) do
    local r = gen_ramp(v[1], v[2], 64)
    for ck,c in ipairs(r) do
        local entry = math.floor(c.b/8)*1024 + math.floor(c.g/8)*32 + math.floor(c.r/8)
        f:write(bytes16(entry))
    end
end
f:close()
