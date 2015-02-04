-- BEHAVIOUR TREES FOR LUA
-- code originally from http://www.blizzhackers.cc/viewtopic.php?f=236&t=490980
-- updated by Leo

if not BTLua2 then
  BTLua2={}
end

function BTLua2.inheritsFrom( baseClass )
    local new_class = {}
    local class_mt = { __index = new_class }

    function new_class:create()
        local newinst = {}
        setmetatable( newinst, class_mt )
        return newinst
    end

    if baseClass then
        setmetatable( new_class, { __index = baseClass } )
    end
    return new_class
end

local cocreate = coroutine.create
local coyield = coroutine.yield
local coresume = coroutine.resume
local codead = function(co) return co == nil or coroutine.status(co) == "dead" end

-- Sleep
function BTLua2.Sleep(timeout)
    return BTLua2.WaitContinue:new(function() return false end, nil, timeout)
end
local function shuffle(t)
  -- see: http://en.wikipedia.org/wiki/Fisher-Yates_shuffle
  local n = #t

  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end

  return t
end

--- BASE NODE
BTLua2.Node = {}
function BTLua2.Node:Tick(pTreeWalker)
   if codead(self.runner) then
      self.runner = cocreate(self.Execute)
   end

   local status, rv = coresume(self.runner, self, pTreeWalker);

   if codead(self.runner) then
      self.last_status = rv
   else
      self.last_status = "Running"
   end

   return self.last_status
end

function BTLua2.Node:Start()
   self.runner = nil
   self.last_status = nil
end

BTLua2.Action = BTLua2.inheritsFrom(BTLua2.Node)
function BTLua2.Action:new(func,...)
   local _func = func
   if type(_func)=="string" then
    _func=loadstring(_func)
   end
   local o = { action = _func, runner = nil, type = "Action", parent = nil,args=arg}
   setmetatable(o, self)
    self.__index = self
    return o
end

function BTLua2.Action:Execute(pTreeWalker)
   if self.args then
     return self.action(pTreeWalker.object,pTreeWalker, unpack(self.args))
   else
     return self.action(pTreeWalker.object,pTreeWalker)
   end
end

BTLua2.Condition = BTLua2.inheritsFrom(BTLua2.Node)
function BTLua2.Condition:new(func,...)
   local _func = func
   if type(_func)=="string" then
    _func=loadstring(_func)
   end
   local o = { action = _func, runner = nil, type = "Action", parent = nil,args=arg}
   setmetatable(o, self)
    self.__index = self
    return o
end

function BTLua2.Condition:Execute(pTreeWalker)
   if self.args then
     return self.action(pTreeWalker.object,pTreeWalker, unpack(self.args))
   else
     return self.action(pTreeWalker.object,pTreeWalker)
   end
end

--- BASE CONTAINER
BTLua2.Container = BTLua2.inheritsFrom(BTLua2.Node)
function BTLua2.Container:new(...)
    local o = { children = {}, runner = nil, type = "Container", parent = nil }
    setmetatable(o, self)
    self.__index = self

    for i,v in ipairs(arg) do
        o:Add(v)
    end

    return o
end

function BTLua2.Container:Add(comp)
   if (type(comp) == "function") then
      comp = BTLua2.Action:new(comp)
   end

    table.insert(self.children, comp)
    comp.parent = self
    return self
end

BTLua2.Sequence = BTLua2.inheritsFrom(BTLua2.Container)
function BTLua2.Sequence:Execute(pTreeWalker)
   for i,comp in ipairs(self.children) do
      comp:Start()
      while comp:Tick(pTreeWalker) == "Running" do
         coyield("Running")
      end

      if (comp.last_status == false) then
         return false
      end
   end

   return true
end

BTLua2.PrioritySelector = BTLua2.inheritsFrom(BTLua2.Container)
function BTLua2.PrioritySelector:Execute(pTreeWalker)
   for i,comp in ipairs(self.children) do
      comp:Start()
      while comp:Tick(pTreeWalker) == "Running" do
         coyield("Running")
      end

      if (comp.last_status == true) then
         return true
      end
   end

   return false
end

BTLua2.RandomSelector = BTLua2.inheritsFrom(BTLua2.Container)
function BTLua2.RandomSelector:Execute(pTreeWalker)
   self.children = shuffle(self.children)
   for i,comp in ipairs(self.children) do
      comp:Start()
      while comp:Tick(pTreeWalker) == "Running" do
         coyield("Running")
      end

      if (comp.last_status == true) then
         return true
      end
   end

   return false
end

BTLua2.AbstractDecorator = BTLua2.inheritsFrom(BTLua2.Node)
function BTLua2.AbstractDecorator:new(predicate, child)
   if (type(child) == "function") then
      child = BTLua2.Action:new(child)
   end
    local _predicate = predicate
    if type(_predicate)=="string" then
       _predicate=loadstring(_predicate)
    end
    local o = { predicate = _predicate, child = child }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Decorator isa AstractDecorator
BTLua2.Decorator = BTLua2.inheritsFrom(BTLua2.AbstractDecorator)
function BTLua2.Decorator:Execute(pTreeWalker)
    local pred_rv = self.predicate()
    self.child:Start()
    if pred_rv then
        while self.child:Tick(pTreeWalker) == "Running" do
           coyield("Running")
        end

        return self.child.last_status
    else
        return false
    end
end

-- DecoratorContinue isa AstractDecorator
BTLua2.DecoratorContinue = BTLua2.inheritsFrom(BTLua2.AbstractDecorator)
function BTLua2.DecoratorContinue:Execute(pTreeWalker)
    local pred_rv = self.predicate()
    if pred_rv then
       self.child:Start()
        while self.child:Tick(pTreeWalker) == "Running" do
           coyield("Running")
        end
        return self.child.last_status
    else
        return true
    end
end

-- Filter isa AstractDecorator
BTLua2.Filter = BTLua2.inheritsFrom(BTLua2.AbstractDecorator)
function BTLua2.Filter:Execute(pTreeWalker)
    local pred_rv = self.predicate()
    self.child:Start()
    if pred_rv then
        while self.child:Tick(pTreeWalker) == "Running" do
           coyield("Running")
        end

        return self.child.last_status
    else
        return false
    end
end

-- Wait isa AbstractDecorator
BTLua2.Wait = BTLua2.inheritsFrom(BTLua2.AbstractDecorator)
function BTLua2.Wait:new(predicate, child, timeout)
    local o = AbstractDecorator.new(self, predicate, child)
    o.timeout = timeout
    return o
end

function BTLua2.Wait:Execute(pTreeWalker)
    local time_start = GetUptimeMS()

    while (GetUptimeMS() - time_start < self.timeout) do
        local pred_rv = self.predicate()
        if pred_rv then
           self.child:Start()
            while self.child:Tick(pTreeWalker) == "Running" do
              coyield("Running")
           end
           return self.child.last_status
        end
        coyield("Running")
    end
    return false
end

-- WaitContinue isa AbstractDecorator
BTLua2.WaitContinue = BTLua2.inheritsFrom(AbstractDecorator)
function BTLua2.WaitContinue:new(predicate, child, timeout)
    local o = AbstractDecorator.new(self, predicate, child)
    o.timeout = timeout
    return o
end

function BTLua2.WaitContinue:Execute(pTreeWalker)
    local time_start = GetUptimeMS()

    while (GetUptimeMS() - time_start < self.timeout) do
        local pred_rv = self.predicate()
        if pred_rv then
           self.child:Start()
            while self.child:Tick(pTreeWalker) == "Running" do
              coyield("Running")
           end
           return self.child.last_status
        end
        coyield("Running")
    end
    return true
end

-- RepeatUntil isa AbstractDecorator
BTLua2.RepeatUntil = BTLua2.inheritsFrom(AbstractDecorator)
function BTLua2.RepeatUntil:new(predicate, child, timeout)
    local o = AbstractDecorator.new(self, predicate, child)
    o.timeout = timeout
    return o
end

function BTLua2.RepeatUntil:Execute(pTreeWalker)
    local time_start = GetUptimeMS()

    while (GetUptimeMS() - time_start < self.timeout) do
        local pred_rv = self.predicate()
        if not pred_rv then
           self.child:Start()
            while self.child:Tick(pTreeWalker) == "Running" do
              coyield("Running")
           end
           if self.child.last_status == false then return false end
            coyield("Running")
        else
            return true
        end
    end
    return false
end

BTLua2.TreeWalker = {}
function BTLua2.TreeWalker:new(pname,pobject,logictree)
   local o = {name=pname, object=pobject, logic = logictree }
   setmetatable(o, self)
    self.__index = self
    return o
end
function BTLua2.TreeWalker:Tick()

   self.logic:Tick(self)

   if (self.logic.last_status ~= "Running") then
      self.logic:Start()
   end
end
