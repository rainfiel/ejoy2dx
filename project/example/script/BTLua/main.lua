globals={}
function copyglobals(ptable)
  globals[ptable]={}
  local _table=globals[ptable]
  for k,v in pairs(_G) do
    _table[k]=type(v)
  end
end
copyglobals("ini")

times=20
cycles=50000

function resetEnv()
  local function addEnv(pstring)
    _G.env[pstring]=0
    _G.env[pstring.."_true"]=0
    _G.env[pstring.."_false"]=0
    _G.env[pstring.."_running"]=0
  end
  _G.env={}
  addEnv("a")
  addEnv("b")
  addEnv("c")
  addEnv("d")
  addEnv("e")
  addEnv("f")
  addEnv("g")
  addEnv("h")
end

function printEnv()
  local function _print(pstring)
    print (pstring..":".._G.env[pstring].."  t:".._G.env[pstring.."_true"].."  f:".._G.env[pstring.."_false"].."  r:".._G.env[pstring.."_running"])
  end
  _print("a")
  _print("b")
  _print("c")
  _print("d")
  _print("e")
  _print("f")
  _print("g")
  _print("h")

end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function love.load()
 require "BTLua"
 require "BTLua2"
 resetEnv()
 print(_VERSION)
end

function love.keypressed(key)
 if key=="escape" then
   love.event.push('quit')
 end

 collectgarbage ("collect")
 collectgarbage ("stop")
 --
 local func
 local test
 local took
 local now
 local min
 local max
 local tot
 if _G["test_"..key] then
   print (" =========================================== kb:"..round(collectgarbage ("count"),3))
   min = -1
   max = -1
   tot = 0
   for time=1,times do
     resetEnv()
     collectgarbage ("collect")

     collectgarbage ("stop")
     func = _G["test_"..key]
     if (_G["test_"..key.."_init"]) then
       _G["test_"..key.."_init"]()
     end
     test = _G["test_"..key.."_desc"]
     local kbini = collectgarbage ("count")
     local now = os.clock()
     ---
     func()
     ---
     local took = os.clock() - now
     local kbfin = collectgarbage ("count")-kbini
     print(test .. " n." .. time.."/"..times.. " took: "..round(took,5).." sec and "..round(kbfin,1).." Kb")
     printEnv()
     if min == -1 or took<min then
      min = took
     end
     if max == -1 or took>max then
      max = took
     end
     tot = tot + took
   end
   print ("Min:"..round(min,5).." Max:"..round(max,5).." Tot:"..round(tot,5).." Avg:"..round(tot/times,5).." over "..times.." times")
 elseif _G["test2_"..key] then
   print (" =========================================== kb:"..round(collectgarbage ("count"),3))
   min = -1
   max = -1
   tot = 0
     resetEnv()
     collectgarbage ("collect")

     collectgarbage ("stop")
     func = _G["test2_"..key]
     if (_G["test2_"..key.."_init"]) then
       _G["test2_"..key.."_init"]()
     end
     test = _G["test2_"..key.."_desc"]
     local kbini = collectgarbage ("count")
     local now = os.clock()
     ---
     func()
     ---
     local took = os.clock() - now
     local kbfin = collectgarbage ("count")-kbini
     print(test ..  " took: "..round(took,5).." sec and "..round(kbfin,1).." Kb")
     printEnv()
 else
  print ("No such test:".."test_"..key.." !")
 end
 --
 collectgarbage ("collect")
 collectgarbage ("restart")
 collectgarbage ("step")
 collectgarbage ("step")
 collectgarbage ("collect")
 print ("kb:"..round(collectgarbage ("count"),3))

end


function love.update()
end

function love.draw()
end

function test_1_init()
  test_1_desc="prova bht"
  bht=BTLua2.TreeWalker:new("prova",nil,
                             BTLua2.PrioritySelector:new(
                               BTLua2.Sequence:new(
                                 BTLua2.Condition:new(func_a),
                                 BTLua2.Action:new(func_b)),
                               BTLua2.PrioritySelector:new(
                                 BTLua2.PrioritySelector:new(
                                   BTLua2.Sequence:new(
                                     BTLua2.Condition:new(func_c),
                                     BTLua2.Action:new(func_d)
                                   ),
                                   BTLua2.Sequence:new(
                                     BTLua2.Condition:new(func_e),
                                     BTLua2.Action:new(func_f)
                                   )
                                 )
                                 ,BTLua2.Sequence:new(
                                   BTLua2.Condition:new(func_g),
                                   BTLua2.Action:new(func_h)
                                 )
                              )
                           ))
end

function test_1()
  local i
  for i=1,cycles do
      bht:Tick()
  end
end

function test_2_init()
  test_2_desc="prova behavtree"
  bht2=BTLua.BTree:new("prova",nil,
                             BTLua.Selector:new(
                               BTLua.Sequence:new(
                                 BTLua.Condition:new(func_a),
                                 BTLua.Action:new(func_b)),
                               BTLua.Selector:new(
                                 BTLua.Selector:new(
                                   BTLua.Sequence:new(
                                     BTLua.Condition:new(func_c),
                                     BTLua.Action:new(func_d)
                                   ),
                                   BTLua.Sequence:new(
                                     BTLua.Condition:new(func_e),
                                     BTLua.Action:new(func_f)
                                   )
                                 )
                                 ,BTLua.Sequence:new(
                                   BTLua.Condition:new(func_g),
                                   BTLua.Action:new(func_h)
                                 )
                              )
                           ),nil,nil)
end

function test_2()
  local i
  for i=1,cycles do
      bht2:run()
  end
  print ("ticknum:"..bht2.ticknum)
end

function func_a()
  _G.env.a = _G.env.a + 1
  if _G.env.a > 3000 then
    _G.env.a_false = _G.env.a_false + 1
    return false
  else
    _G.env.a_true = _G.env.a_true + 1
    return true
  end
end

function func_b()
  _G.env.b = _G.env.b + 1
  if _G.env.b > 3000 then
    _G.env.b_false = _G.env.b_false + 1
    return false
  else
    if _G.env.b % 2 == 1 then
      _G.env.b_running = _G.env.b_running + 1
      return "Running"
      --coroutine.yield("Running")
    end
    _G.env.b_true = _G.env.b_true + 1
    return true
  end
end

function func_c()
  _G.env.c = _G.env.c + 1
  if _G.env.c > 3000 then
    _G.env.c_false = _G.env.c_false + 1
    return false
  else
    _G.env.c_true = _G.env.c_true + 1
    return true
  end
end

function func_d()
  _G.env.d = _G.env.d + 1
  if _G.env.d > 3000 then
    _G.env.d_false = _G.env.d_false + 1
    return false
  else
    _G.env.d_true = _G.env.d_true + 1
    return true
  end
end


function func_e()
  _G.env.e = _G.env.e + 1
  if _G.env.e > 3000 then
    _G.env.e_false = _G.env.e_false + 1
    return false
  else
    _G.env.e_true = _G.env.e_true + 1
    return true
  end
end

function func_f()
  _G.env.f = _G.env.f + 1
  if _G.env.f >3000 then
    _G.env.f_false = _G.env.f_false + 1
    return false
  else
    _G.env.f_true = _G.env.f_true + 1
    return true
  end
end

function func_g()
  _G.env.g = _G.env.g + 1
  if _G.env.g > 3000 then
    _G.env.g_false = _G.env.g_false + 1
    return false
  else
    _G.env.g_true = _G.env.g_true + 1
    return true
  end
end

function func_h()
  _G.env.h = _G.env.h + 1
  if _G.env.h > 3000 then
    _G.env.h_false = _G.env.h_false + 1
    return false
  else
    _G.env.h_true = _G.env.h_true + 1
    return true
  end
end

myobject={}
myobject.data = ""
function myobject:action(pbehavtree,...)
  print("action ".."#"..self.data.."#")
  if select("#",...)>0 then
    for k,v in pairs{...} do
      print("args "..k.." : "..v)
    end
  end
  return true
end
function myobject:condition(pbehavtree,...)
  print("condition ".."#"..self.data.."#")
  if select("#",...)>0 then
    for k,v in pairs{...} do
      print("args "..k.." : "..v)
    end
  end
  return true
end
function myobject:new(pdata)
 local _o = {}
 setmetatable(_o, self)
 self.__index = self
 _o.data = pdata
 return _o
end

myobject_a=myobject:new("a")

myobject_b=myobject:new("b")

function test2_a_init()
  test2_a_desc="prova read from file test.lua"
  bht2=BTLua.BTree:new("prova",myobject_b,
                             nil,nil,nil)
  local _table = loadstring(love.filesystem.read("test.lua"))()
  bht2:parseTable(nil,_table,nil)
end

function test2_a()
  local i
  bht2:run()
  print ("ticknum:"..bht2.ticknum)
end

function globalaction(pobject,pbehavtree,...)
  print("globalaction")
  if select("#",...)>0 then
    for k,v in pairs{...} do
      print("args "..k.." : "..v)
    end
  end
  return true
end


function test2_b_init()
  test2_b_desc="prova read from file test2.lua"
  bht2=BTLua.BTree:new("prova",myobject_b,
                             nil,nil,nil)
  local _table = loadstring(love.filesystem.read("test2.lua"))()
  bht2:parseTable(nil,_table,nil)
end

function test2_b()
  local i
  for i=1,5 do
    sleep(0.5)
    bht2:run()
  end
  print ("ticknum:"..bht2.ticknum)
end

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

function test2_z_init()
  test2_z_desc="verify globals"
end

function test2_z()
  copyglobals("now")
  for k,v in pairs(globals.now) do
    if globals.ini[k]==nil then
      print(k.." "..v)
    end
  end
  copyglobals("ini")
end


function test2_c_init()
  test2_c_desc="prova string functions"
  bht2=BTLua.BTree:new("prova",myobject_b,
                      BTLua.Selector:new(
                        BTLua.Sequence:new(
                          BTLua.Condition:new("#condition","a",2),
                          BTLua.Action:new("!globalaction")
                        ),
                        BTLua.Sequence:new(
                          BTLua.Condition:new("#condition","b",3),
                          BTLua.Action:new("!globalaction")
                        )
                      )
                      ,nil,nil)
end

function test2_c()
  local i
  bht2:run()
  print ("ticknum:"..bht2.ticknum)
end
