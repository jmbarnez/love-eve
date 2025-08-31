
local ctx = require("src.core.state")
local lf  = love.filesystem

local M = {}

-- Simple serializer to Lua source (no external libs, numbers/strings/booleans/tables only)
local function serializeValue(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "string" then
    return string.format("%q", v)
  elseif t == "table" then
    local parts = {"{"}
    local first = true
    for k,val in pairs(v) do
      local key
      if type(k) == "string" and k:match("^[_%a][_%w]*$") then
        key = k
      else
        key = "["..serializeValue(k, indent.."  ").."]"
      end
      local entry = string.format("%s  %s = %s", indent, key, serializeValue(val, indent.."  "))
      table.insert(parts, entry .. ",")
      first = false
    end
    table.insert(parts, indent.."}")
    return table.concat(parts, "\n")
  else
    return "nil"
  end
end

local function serialize(tbl)
  return "return " .. serializeValue(tbl, "")
end

local function deserializeLua(str)
  local chunk, err = lf.load("save.lua")
  if not chunk then return false end
  local ok, data = pcall(chunk)
  if not ok or type(data) ~= "table" then return false end
  -- apply to ctx.player
  if data.player and ctx.player then
    for k,v in pairs(data.player) do 
      if k ~= "vx" and k ~= "vy" then
        ctx.player[k] = v 
      end
    end
    -- Always reset to spawn position at docking area
    ctx.player.x = ctx.station.x + 150
    ctx.player.y = ctx.station.y
    ctx.player.docked = false
  end
  return true
end

function M.save()
  -- Player persistence disabled for testing
  -- local p = ctx.player
  -- local t = {
  --   player={
  --     -- Don't save position - always spawn at docking area
  --     hp=p.hp,maxHP=p.maxHP,shield=p.shield,maxShield=p.maxShield,
  --     energy=p.energy,maxEnergy=p.maxEnergy,
  --     accel=p.accel, maxSpeed=p.maxSpeed, damage=p.damage,
  --     fireCooldownMax=p.fireCooldownMax, bulletSpeed=p.bulletSpeed, bulletLife=p.bulletLife,
  --     spread=p.spread, credits=p.credits, level=p.level, xp=p.xp, xpToNext=p.xpToNext,
  --   }
  -- }
  -- local s = serialize(t)
  -- lf.write("save.lua", s)
end

function M.load()
  -- Player persistence disabled for testing
  -- if not lf.getInfo("save.lua") then return false end
  -- return deserializeLua()
  return false
end

return M
