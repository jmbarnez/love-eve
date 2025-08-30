
local ctx  = require("src.core.ctx")
local util = require("src.core.util")

local M = {}

local function bar(x,y,w,h, value, max, colFG, colBG)
  colBG = colBG or {0.15,0.15,0.18,0.8}
  colFG = colFG or {0.3,0.8,0.95,1}
  love.graphics.setColor(colBG)
  love.graphics.rectangle("fill", x,y,w,h, 4,4)
  local t = math.max(0, math.min(1, value/max))
  love.graphics.setColor(colFG)
  love.graphics.rectangle("fill", x,y,w*t,h, 4,4)
  love.graphics.setColor(0,0,0,0.2)
  love.graphics.rectangle("line", x,y,w,h, 4,4)
  love.graphics.setColor(1,1,1,1)
end

function M.draw()
  love.graphics.push()
  love.graphics.origin()
  love.graphics.scale(ctx.G.UI_SCALE)
  local W,H = love.graphics.getWidth()/ctx.G.UI_SCALE, love.graphics.getHeight()/ctx.G.UI_SCALE

  bar(20,H-90, 260,16, ctx.player.hp, ctx.player.maxHP, {0.95,0.25,0.2,1})
  love.graphics.print("Hull", 22, H-108)
  bar(20,H-66, 260,16, ctx.player.shield, ctx.player.maxShield, {0.2,0.6,1,1})
  love.graphics.print("Shield", 22, H-84)
  bar(20,H-42, 260,16, ctx.player.energy, ctx.player.maxEnergy, {0.2,1,0.6,1})
  love.graphics.print("Energy", 22, H-60)

  bar(20,H-18, 260,12, ctx.player.xp, ctx.player.xpToNext, {1,0.85,0.3,1})
  love.graphics.print(string.format("Lvl %d  XP %d/%d", ctx.player.level, ctx.player.xp, ctx.player.xpToNext), 22, H-36)

  love.graphics.print(string.format("Credits: %d", ctx.player.credits), 320, H-36)

  if ctx.state.showHelp then
    local lines = {
      "WASD move, Shift boost, Space quick-stop",
      "LMB fire, RMB waypoint, F follow mouse",
      "E to dock at station (buy upgrades)",
      "Tab minimap, H help, F5 save, F9 load",
    }
    local bx,by = 20, 20
    love.graphics.setColor(0,0,0,0.35); love.graphics.rectangle("fill", bx-10, by-12, 460, #lines*18+24, 8,8); love.graphics.setColor(1,1,1,1)
    for i,s in ipairs(lines) do love.graphics.print(s, bx, by + (i-1)*18) end
  end

  local dx = ctx.player.x - ctx.station.x
  local dy = ctx.player.y - ctx.station.y
  if util.len(dx,dy) < 120 then
    love.graphics.printf("Press E to Dock / Undock", 0, H-140, W, "center")
  end

  -- Minimap
  local mapSize = ctx.state.minimapExpanded and 240 or 140
  local mx = W - mapSize - 20
  local my = 20
  love.graphics.setColor(0,0,0,0.35); love.graphics.rectangle("fill", mx-6, my-6, mapSize+12, mapSize+12, 8,8)
  love.graphics.setColor(0.12,0.12,0.15,1); love.graphics.rectangle("fill", mx, my, mapSize, mapSize)
  love.graphics.setColor(0.3,0.3,0.36,1); love.graphics.rectangle("line", mx, my, mapSize, mapSize)
  local half = ctx.G.WORLD_SIZE
  local function toMini(wx,wy)
    local u = (wx + half) / (2*half)
    local v = (wy + half) / (2*half)
    return mx + u*mapSize, my + v*mapSize
  end
  -- station
  do
    local sx,sy = toMini(ctx.station.x, ctx.station.y)
    love.graphics.setColor(0.7,1,0.9,1); love.graphics.circle("fill", sx,sy, 4)
  end
  -- enemies
  love.graphics.setColor(1,0.35,0.35,1)
  for _,e in ipairs(ctx.enemies) do
    local ex,ey = toMini(e.x,e.y)
    love.graphics.rectangle("fill", ex-2,ey-2, 4,4)
  end
  -- player
  do
    local px,py = toMini(ctx.player.x, ctx.player.y)
    love.graphics.setColor(0.4,0.9,1,1); love.graphics.circle("fill", px,py, 4)
  end
  love.graphics.setColor(1,1,1,1)

  love.graphics.pop()
end

return M
