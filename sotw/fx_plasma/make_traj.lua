local pathfilename = arg[1]
local filename = pathfilename:gsub(".*/","")
local outfilename = 'data/'..filename:gsub("%.%w+$",".bin")

local file,err = io.open(pathfilename,"rb")
if file == nil then print(err) os.exit(false) end
local f = file:read("*a")
file:close()

local im_idsz = f:byte(1)
local typ = f:byte(3)
if typ ~= 1 then print("unsupported image type code ("..typ..")") os.exit(false) end
local width = f:byte(13) + f:byte(14)*256
local height = f:byte(15) + f:byte(16)*256
local cm_orig = f:byte(4) + f:byte(5)*256
local cm_len = f:byte(6) + f:byte(7)*256
local cm_entsz = f:byte(8)
local im_pxsz = f:byte(17)
local im_desc = f:byte(18)
if cm_entsz ~= 24 then print("colormap entry size must be 24. ("..cm_entsz..")") os.exit(false) end

local pos = 19
local palette = {}
for i=1,cm_len do
  local c = {}
  c.b,c.g,c.r = f:byte(pos,pos+2)
  -- print(c.r,c.g,c.b)
  table.insert(palette,c)
  pos = pos+3
end
local pix = {}
for i=1,height do
  pix[height-i+1] = table.pack(f:byte(pos,pos+width-1))
  pos = pos+width
end

local f,err = io.open(outfilename,"wb")
if f == nil then print(err) os.exit(false) end
for x=1,width do
    for y=1,height do
        if pix[y][x] ~= 0 then 
            f:write(string.char(x-1, y-1));
        end
    end
end
f:close()
