#!/usr/bin/env lua

local duration = 3*60*1000
local tempo = 418
local afterbeat = tempo * 0.5

local beatcount = duration / tempo

local f = assert(io.open("../source/sync_dat.c", "wb"))
f:write("#include <gba.h>\nconst u16 sync_d[] = {\n")
local prev = 0
for i=4,beatcount do
    f:write(string.format("%d, %d,\n", (i-prev) * tempo, (i%4 ~= 0) and 1 or 3))
    prev = i
    if i >= 15 then
        local a = i + 0.5
        f:write(string.format("%d, %d,\n", (a-prev) * tempo, (i%2 == 0) and 12 or 4))
        prev = a
    end
end
f:write("};")
f:close()
