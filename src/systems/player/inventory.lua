local ctx = require("src.core.state")
local Items = require("src.models.items.registry")

local M = {}

function M.add(id, n)
  n = n or 1
  local inv = ctx.player.inventory
  inv[id] = (inv[id] or 0) + n
  return inv[id]
end

function M.remove(id, n)
  n = n or 1
  local inv = ctx.player.inventory
  local have = inv[id] or 0
  local take = math.min(have, n)
  inv[id] = have - take
  if inv[id] <= 0 then inv[id] = nil end
  return take
end

function M.count(id)
  return ctx.player.inventory[id] or 0
end

function M.has(id, n)
  return (ctx.player.inventory[id] or 0) >= (n or 1)
end

return M
