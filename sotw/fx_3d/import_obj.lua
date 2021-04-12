
inverseorder = false
yscale = nil
matsh = 0
local a = 1
while string.sub(arg[a],1,1) == "-" do
  if arg[a] == "-i" then
    inverseorder = true
  elseif arg[a] == "-y" then
    a = a+1
    yscale = tonumber(arg[a])
  elseif arg[a] == "-m" then
    a = a+1
    matsh = tonumber(arg[a])
  else
    print("invalid switch \""..arg[a].."\"")
    os.exit(false)
  end
  a = a+1
end
infilename = arg[a]
basename = string.match(infilename, "(%g+)%.%g+") or infilename
dir = string.match(infilename, "^%g+/")
outfilename = arg[a+1] or basename..".s"
name = string.gsub(string.match(outfilename,".*/(%g+)%.%g+"),"[^%w]","_")

local objects = {}
local obj
local mat = 0
local mtllib

function mtllib_read(filename)
  local lib = {}
  local nmat = 0
  local mtl
  local f,err = io.open(filename,"r")
  if f == nil then error(err) end
  for line in f:lines() do
    line = line:match("^%s*(.*[^%s])%s*$")
    if line and line ~= "" and line:sub(1,1) ~= "#" then
      local key,rest = line:match("(%w+) (.*)")
      local args = {}
      for a in rest:gmatch("%g+") do
        table.insert(args,tonumber(a) or a)
      end
      if key == "newmtl" then
        local name = args[1]
        nmat = nmat+1
        mtl = {id=nmat,name=name}
        lib[nmat] = mtl
        lib[name] = mtl
      else
        mtl[key] = (#args == 1) and args[1] or args
      end
    end
  end
  f:close()
  return lib
end

local f,err = io.open(infilename,"r")
if f == nil then error(err) end
for line in f:lines() do
  line = line:match("^%s*(.*[^%s])%s*$")
  if line and string.sub(line,1,1) ~= "#" then
    local cmd,rest = line:match("(%w+) (.*)")
    local args = {}
    -- print(cmd,rest)
    for a in rest:gmatch("%g+") do
      local v = tonumber(a) or a
      table.insert(args,v)
    end
    -- if cmd == "o" then
    --   obj = {name=rest,v={},f={}}
    --   table.insert(objects,obj)
    if cmd == "v" then
      local v = {x=args[1],y=args[2],z=args[3]}
      if obj == nil then
        obj = {name="noname",v={},f={}}
        table.insert(objects,obj)
      end
      table.insert(obj.v,v)
    elseif cmd == "f" then
      local v = {mat=mat}
      for i=1,#args do
        local a,n = args[inverseorder and (#args-i+1) or i]
        if type(a) == "string" then
          a,n = a:match("(%d+)//(%d+)")
          a = tonumber(a)
        end
        table.insert(v,a)
      end
      local ok = false
      while not ok and #v >= 3 do
        ok = true
        for i=1,#v-2 do
          local j,k = i+1,i+2
          if (j > #v) then j = j - #v end
          if (k > #v) then k = k - #v end
          local v1 = {x=obj.v[v[j]].x-obj.v[v[i]].x,y=obj.v[v[j]].y-obj.v[v[i]].y,z=obj.v[v[j]].z-obj.v[v[i]].z}
          local v2 = {x=obj.v[v[k]].x-obj.v[v[j]].x,y=obj.v[v[k]].y-obj.v[v[j]].y,z=obj.v[v[k]].z-obj.v[v[j]].z}
          local n1 = math.sqrt(v1.x*v1.x+v1.y*v1.y+v1.z*v1.z)
          local n2 = math.sqrt(v2.x*v2.x+v2.y*v2.y+v2.z*v2.z)
          local cos = (v1.x*v2.x+v1.y*v2.y+v1.z*v2.z)/(n1*n2)
          if (cos > 0.999) then
            table.remove(v,j)
            ok = false
            break
          end
        end
      end
      if #v >= 3 then
        local v1 = {x=obj.v[v[2]].x-obj.v[v[1]].x,y=obj.v[v[2]].y-obj.v[v[1]].y,z=obj.v[v[2]].z-obj.v[v[1]].z}
        local v2 = {x=obj.v[v[3]].x-obj.v[v[2]].x,y=obj.v[v[3]].y-obj.v[v[2]].y,z=obj.v[v[3]].z-obj.v[v[2]].z}
        local p = {x=v1.y*v2.z-v1.z*v2.y,y=v1.z*v2.x-v1.x*v2.z,z=v1.x*v2.y-v1.y*v2.x}
        local n = math.sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
        if n ~= 0 then
          local n1 = 1/n
          v.n = {x=p.x*n1,y=p.y*n1,z=p.z*n1}
          table.insert(obj.f,v)
        end
      end
    elseif cmd == "mtllib" then
      mtllib = mtllib_read(dir..args[1])
    elseif cmd == "usemtl" then
      mat = mtllib[args[1]].id
    end
  end
end
f:close()

local min = {x=math.huge,y=math.huge,z=math.huge}
local max = {x=-math.huge,y=-math.huge,z=-math.huge}
obj = objects[1]
for _,v in ipairs(obj.v) do
  if v.x > max.x then max.x = v.x end
  if v.x < min.x then min.x = v.x end
  if v.y > max.y then max.y = v.y end
  if v.y < min.y then min.y = v.y end
  if v.z > max.z then max.z = v.z end
  if v.z < min.z then min.z = v.z end
end

local sh = {x=-(min.x+max.x)*.5,y=-(min.y+max.y)*.5,z=-(min.z+max.z)*.5}
if yscale then
  local y = max.y + sh.y
  scale = yscale/y
else
  scale = 260/math.max(max.x+sh.x,max.y+sh.y,max.z+sh.z)
end

function sc(x)
  return math.floor(x*scale)
end

function fhex(x)
  local y = math.floor(x*32768)
  if y >= 32768 then y = 32767 end
  if y == 0 then y = 0 end
  -- if y < 0 then y = 65536+y end
  -- return string.format("0x%04x",y)
  return y
end

local f,err = io.open(outfilename,"w")
if f == nil then error(err) end
f:write("\t.global "..name.."\n")
f:write("\t.section .rodata\n")
f:write(name..":\n")
f:write("\t.hword\t"..#obj.v..","..#obj.f.."\n")
for _,v in ipairs(obj.v) do
  f:write("\t.hword\t"..sc(v.x+sh.x)..","..sc(v.y+sh.y)..","..sc(v.z+sh.z).."\n")
end
for _,v in ipairs(obj.f) do
  local n = v.n
  f:write("\t.hword\t"..(v.mat-1+matsh)..","..fhex(n.x)..","..fhex(n.y)..","..fhex(n.z).."\n")
  f:write("\t.hword\t"..#v)
  for i=1,#v do
    f:write(","..(v[i]-1)*6)
  end
  f:write("\n")
end
f:write("\n")
f:write("\t.global "..name.."_palette_data\n")
f:write(name.."_palette_data:\n")
for _,mtl in ipairs(mtllib) do
  f:write("\t.byte\t0, 0, 0, 31\n\t.byte\t")
  for i=1,3 do
    f:write(math.floor(mtl.Kd[i]*255.99)..", ")
  end
  f:write("1\n")
end
f:write("\t.byte\t0, 0, 255, 0\n")
f:close()
