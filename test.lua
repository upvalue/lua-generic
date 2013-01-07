local g = require('init')
local Object, Class, generic = g.Object, g.Class, g.Generic

local test = g.Object:clone()
assert(rawget(test, 'prototype') == g.Object)
assert(test.prototype == g.Object)


local Asteroid = g.Class:clone()
local Ship = g.Class:clone()
local Gold = g.Class:clone()
local Bad = g.Class:clone()

local player = Ship:new()
local asteroid1 = Asteroid:new()

local collide = g.generic('collide')

collide:method(Ship, Asteroid, function(ship, asteroid)
  print('BOOM') 
end)

collide:method(Ship, Gold, function(ship, gold)
  print('$$$')
end)

collide(player, asteroid1)
print()
--print('!! call2')
--collide(player, Bad:new())
--print()
print('!! call3')
collide(player, Gold:new())
print()

-- print(collide[1])
-- collide(asteroid1, player)
-- collide(player, asteroid1)
