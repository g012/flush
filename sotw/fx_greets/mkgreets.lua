

-- local pathfilename = arg[1]
-- local filename = pathfilename:gsub(".*/","")
-- local outfilename = arg[2] or filename:gsub("%.%w+$",".c")
local pathfilename = "../_gfx/greets/font.tga"
local outfilename = "source/greets_bg.s"
local name = outfilename:gsub(".*/",""):match("(%g+)%.%w+$")

local file,err = io.open(pathfilename,"rb")
if file == nil then print(err) os.exit(false) end
local f = file:read("*a")
file:close()

local im_idsz = f:byte(1)
local typ = f:byte(3)
if typ ~= 3 then print("unsupported image type code ("..typ..")") os.exit(false) end
local width = f:byte(13) + f:byte(14)*256
local height = f:byte(15) + f:byte(16)*256
local cm_orig = f:byte(4) + f:byte(5)*256
local cm_len = f:byte(6) + f:byte(7)*256
local cm_entsz = f:byte(8)
local im_pxsz = f:byte(17)
local im_desc = f:byte(18)
if cm_entsz ~= 0 then print("colormap entry size must be 0. ("..cm_entsz..")") os.exit(false) end
if cm_len ~= 0 then print("colormap size must be 0. ("..cm_len..")") os.exit(false) end

print("pix size = "..width.."x"..height)

local pos = 19+im_idsz
local pix = {}
for i=1,height do
  pix[height-i+1] = table.pack(f:byte(pos,pos+width-1))
  pos = pos+width
end

local x0 = {1}
local x1 = {}
local emp = false
for i=1,width do
  local e = true
  for j=1,height do
    if pix[j][i] == 0 then
      e = false
    end
  end
  if e and not emp then
    table.insert(x1,i)
  elseif not e and emp then
    table.insert(x0,i)
  end
  emp = e
end

local pos = {}
local chars="abcdefghijklmnopqrstuvwxyz0123456789-.!?"
for i=1,chars:len() do
  local c = chars:sub(i,i)
  pos[c] = {x0=x0[i],x1=x1[i]}
end

greets = {}
table.insert(greets, "aggression")
table.insert(greets, "blabla")
table.insert(greets, "cerebral vortex")
table.insert(greets, "checkpoint")
table.insert(greets, "dead hackers society")
table.insert(greets, "dune")
table.insert(greets, "punkfloyd")
table.insert(greets, "live!")
table.insert(greets, "lnx")
table.insert(greets, "mankind")
table.insert(greets, "mjj prod")
table.insert(greets, "mystic bytes")
table.insert(greets, "noextra")
table.insert(greets, "paradox")
table.insert(greets, "popsy team")
table.insert(greets, "razor1911")
table.insert(greets, "reboot")
table.insert(greets, "tmp")
table.insert(greets, "undead sceners")
table.insert(greets, "xmen")
math.randomseed(42)
rnds = {}
for _,v in ipairs(greets) do
  rnds[v] = math.random()
end
table.sort(greets,function(x,y) return rnds[x]<rnds[y] end)
grstr = table.concat(greets," - ")
grstr = grstr.." - special thanx to aubepine and yaya! - "
print(grstr)

local outpix = {}
for i=1,400 do
  outpix[i] = {}
end
local x,y = 1,1
local i = 1
local done = false
while not done do
  local c = grstr:sub(i,i)
  if c == " " then
    x = x + 2
  else
    local p = pos[c]
    for k = p.x0,p.x1-1 do
      if x > 240 then
        x = x - 240
        y = y + height
        if y > 360 then
          done = true
          break
        end
      end
      for h = 1,height do
        outpix[y+h-1][x] = (pix[h][k]==0) and 33 or 0
      end
      x = x+1
    end
  end
  x = x+1
  i = i+1
  if i > grstr:len() then
    i = 1
  end
end

local file,err = io.open(outfilename,"w")
if file == nil then print(err) os.exit(false) end
file:write("\t.global\t"..name.."\n")
file:write("\t.section .rodata\n")
file:write("\t.align\n")
file:write(name..":\n")
for y=1,360 do
  for x=1,240/16 do
    file:write("\t.byte")
    for x2=1,16 do
      file:write((x2==1) and "\t" or ",")
      file:write(outpix[y][(x-1)*16+x2] or 0)
    end
    file:write("\n")
  end
end

file:close()
