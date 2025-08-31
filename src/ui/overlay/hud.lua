local ctx = require("src.core.state")
local theme = require("src.ui.theme")
local bars = require("src.ui.components.bars")

local M = {}

function M.draw()
  if not ctx.player then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local p = ctx.player

<<<<<<< HEAD
  -- Status bars (top-left)
  local x, y = 20, 20
  local w, h = 180, 14
  local spacing = 16
  bars.compact(x, y, w, h, p.hp, p.maxHP, theme.warning)
  bars.compact(x, y + spacing, w, h, p.shield, p.maxShield, theme.primary)
  bars.compact(x, y + spacing * 2, w, h, p.energy, p.maxEnergy, theme.energy)

  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)

  -- Minimap (top-right)
  local mapSize = 120
  local mapX, mapY = W - mapSize - 20, 20
  love.graphics.setColor(theme.bg)
  love.graphics.rectangle("fill", mapX, mapY, mapSize, mapSize, 4)
  love.graphics.setColor(theme.border)
  love.graphics.rectangle("line", mapX, mapY, mapSize, mapSize, 4)

  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.3)
=======
  -- Enhanced sci-fi status bars (top-left)
  local x, y = 20, 20
  local w, h = 220, 20
  local spacing = 25

  -- Hull integrity
  bars.sciFi(x, y, w, h, p.hp, p.maxHP, theme.warning, "HULL", true)

  -- Shield status
  bars.sciFi(x, y + spacing, w, h, p.shield, p.maxShield, theme.primary, "SHIELD", true)

  -- Energy core
  bars.sciFi(x, y + spacing * 2, w, h, p.energy, p.maxEnergy, theme.energy, "ENERGY", true)

  -- Energy regeneration indicator
  if p.energy < p.maxEnergy then
    love.graphics.setColor(theme.energy[1] * 0.7, theme.energy[2] * 0.7, theme.energy[3] * 0.7, 0.6)
    love.graphics.printf("+REGEN", x, y + spacing * 3 + 2, w, "center")
  end

  -- Status indicators with icons
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)

  -- Minimap (top-right) - Enhanced with better styling
  local mapSize = 140
  local mapX, mapY = W - mapSize - 10, 10

  -- Minimap background with sci-fi border
  love.graphics.setColor(0.05, 0.08, 0.12, 0.9)
  love.graphics.rectangle("fill", mapX, mapY, mapSize, mapSize, 4)

  -- Minimap border
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", mapX, mapY, mapSize, mapSize, 4)

  -- Inner grid
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.3)
  love.graphics.setLineWidth(1)
>>>>>>> a91d4cc (Fixed combat and movement)
  for i = 1, 3 do
    local gx = mapX + (mapSize / 4) * i
    local gy = mapY + (mapSize / 4) * i
    love.graphics.line(gx, mapY, gx, mapY + mapSize)
    love.graphics.line(mapX, gy, mapX + mapSize, gy)
  end

  local half = ctx.G.WORLD_SIZE
  local function toMini(wx, wy)
    local u = (wx + half) / (2 * half)
    local v = (wy + half) / (2 * half)
    return mapX + u * mapSize, mapY + v * mapSize
  end

<<<<<<< HEAD
  if ctx.station then
    local sx, sy = toMini(ctx.station.x, ctx.station.y)
    love.graphics.setColor(theme.energy)
    love.graphics.circle("fill", sx, sy, 3)
  end

  love.graphics.setColor(theme.warning)
  for _, e in ipairs(ctx.enemies or {}) do
    local ex, ey = toMini(e.x, e.y)
    love.graphics.rectangle("fill", ex - 1, ey - 1, 2, 2)
  end

  local px, py = toMini(p.x, p.y)
  love.graphics.setColor(theme.primary)
  love.graphics.circle("fill", px, py, 3)
=======
  -- Station marker
  if ctx.station then
    local sx, sy = toMini(ctx.station.x, ctx.station.y)
    love.graphics.setColor(theme.energy[1], theme.energy[2], theme.energy[3], 0.9)
    love.graphics.circle("fill", sx, sy, 4)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", sx, sy, 4)
  end

  -- Enemy markers
  love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
  for _, e in ipairs(ctx.enemies or {}) do
    local ex, ey = toMini(e.x, e.y)
    love.graphics.rectangle("fill", ex - 2, ey - 2, 4, 4)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.rectangle("line", ex - 2, ey - 2, 4, 4)
    love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
  end

  -- Player marker
  local px, py = toMini(p.x, p.y)
  love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 1)
  love.graphics.circle("fill", px, py, 3)
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.circle("line", px, py, 3)

  -- Energy warning indicator
  if p.energy < p.maxEnergy * 0.3 then
    love.graphics.setColor(theme.energy[1], theme.energy[2], theme.energy[3], 0.6)
    love.graphics.printf("LOW ENERGY", x, y + spacing * 3 + 5, w, "center")
  end
>>>>>>> a91d4cc (Fixed combat and movement)
end

return M

