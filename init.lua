-- lua-generic - Small footprint single-inheritance prototypal object system with support for multiple dispatch
-- Copyright (c) 2013 ioddly
-- Released under the Boost License: <http://www.boost.org/LICENSE_1_0.txt>

-- Slot lookup
local function lookup(object, key)
  if type(key) == "number" then
    return rawget(object, key)
  end
  while object do
    local test = rawget(object, key)
    if test then
      return test
    end
    object = rawget(object, 'prototype')
  end
end

local function _tostring(object)
  return object:tostring()
end

-- Objects
local object_mt = { __index = lookup, __tostring = _tostring }

local Object = {}
setmetatable(Object, object_mt)

function Object:clone(o)
  o = o or {}
  setmetatable(o, object_mt)
  rawset(o, 'prototype', self)
  return o
end

function Object:is_a(other)
  local object, depth = self, 0
  while object do
    if object == other then return depth end
    depth = depth + 1
    object = rawget(object, 'prototype')
  end
end

function Object:tostring()
  return '<Object>'
end

-- Classes

local Class = Object:clone()

function Class:new(...)
  local o = Object:clone()
  rawset(o, 'prototype', self)
  o:initialize(...)
  return o
end

function Class:initialize(table)
  if type(table) == 'table' then
    for k,v in pairs(table) do
      self[k] = v
    end
  end
end

-- Generics implementation

local function generic_search(self, arg, argn)
  local method, method_specificity = nil, -1
  -- Search through method signatures (most recently added first)
  for i = #self, 1, -1 do
    -- Search through arguments
    local m_argn = #self[i] - 1
    -- If this method accepts the correct amount of arguments
    if m_argn == argn then
      -- Specificity describes how good of a match this method is to the arguments given
      local specificity = 0

      -- Check each argument
      for j = 1, m_argn do
        local match = arg[j]:is_a(self[i][j])
        -- If this does not match, then discard it
        if not match then
          specificity = -1
          break
        end

        specificity = specificity + match
      end

      -- Exact match
      if specificity >= 0 then 
        if specificity == 0 then
          method = self[i][#self[i]]
          break
        end
        
        -- If we haven't already found a better match
        if method_specificity == -1 or method_specificity > specificity then
          method = self[i][#self[i]]
        end
      end
    end
  end
  return method
end

local function generic_describe(self)
  return 'generic("' .. self.name .. '", '.. self.argc .. ')'
end

local function generic_apply(self, ...)
  local arg = {...}
  local argc = select('#', ...)
  if argc < self.argc then
    error(self:describe() .. ': did not receive enough arguments')
  end
  local search = generic_search(self, arg, self.argc)
  if not search then
    error(self:describe() .. ': failed to find an appropriate method for arguments ')
  end
  return search(...)
end

local function generic_method(self, ...)
  local arg = {n = select('#', ...), ...}

  for i = 1, arg.n do
    if type(arg[i]) == 'function' then
      if i ~= arg.n then
        error('generic("' .. self.name .. '"):method received function before the end of argument list')
      else
        break
      end
    end

    if i == arg.n then
      if type(arg[i]) ~= 'function' then
        error(self:describe() .. ':method expected function as final argument')
      end
    else
      if not rawget(arg[i], 'prototype') then
        error(self:describe() .. ':method received non-object as argument')
      end
    end
  end

  table.insert(self, arg)
end

local function generic_method2(self, a, b, fn)
  generic_method(self, a, b, fn)
  generic_method(self, b, a, function(b, a) fn(a, b) end)
end
  
local generic_mt = {
  __call = generic_apply
}

local function generic(name, argc, ...)
  assert(type(name) == 'string')
  assert(type(argc) == 'number')
  local g = { name = name, method = generic_method, method2 = generic_method2,
              argc = argc, describe = generic_describe }
  setmetatable(g, generic_mt)
  return g 
end

return { Object = Object, Class = Class, generic = generic }
