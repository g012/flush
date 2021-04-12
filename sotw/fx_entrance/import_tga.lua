

local pathfilename = arg[1]
local filename = pathfilename:gsub(".*/","")
local outfilename = arg[2] or filename:gsub("%.%w+$",".c")
local name = outfilename:gsub(".*/",""):match("(%g+)%.%w+$")

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

local wspr = 64
local hspr = 32
local hwwspr = 64
local hwhspr = 32
local size = width*height
local xblocks = width/8
local yblocks = height/8
local nblocks = size/64
local xspr = width/wspr
local yspr = height/hspr
local nspr = xspr*yspr
local sprites = {}
for j=0,yspr-1 do
  for i=0,xspr-1 do
    local s = {}
    table.insert(sprites,s)
    for yb=0,hwhspr/8-1 do
      local ypos = (yb < hspr/8) and (j*hspr + yb*8) or -1
      for xb=0,hwwspr/8-1 do
        local xpos = (xb < wspr/8) and (i*wspr + xb*8) or -1
        local b = {}
        for y=0,7 do
          for x=0,7 do
            local p = (ypos~=-1 and xpos~=-1) and pix[ypos+y+1][xpos+x+1] or 0
            table.insert(s,p)
          end
        end
      end
    end
  end
end

file,err = io.open(outfilename,"w")
if file == nil then print(err) os.exit(false) end
file:write("#include <gba.h>\n")
file:write("const u16 "..name.."_palette["..cm_len.."] = {\n")
for i=1,cm_len do
  local c = palette[i]
  local entry = math.floor(c.b/8)*1024 + math.floor(c.g/8)*32 + math.floor(c.r/8)
  file:write("  "..string.format("0x%04x",entry)..",\n")
end
file:write("};\n")
file:write("const u8 "..name.."["..(hwwspr*hwhspr*nspr/2).."] = {\n")
for _,s in ipairs(sprites) do
  for j=1,#s/32 do
    file:write("  ")
    for i=1,32,2 do
      local p1 = s[(j-1)*32+i]
      local p2 = s[(j-1)*32+i+1]
      file:write((p2*16+p1)..", ")
      -- file:write((p1)..", ")
    end
    file:write("\n")
  end
end
file:write("};\n")
file:close()
