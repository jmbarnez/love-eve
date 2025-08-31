Alocal ctx = require("src.core.state")
local theme = require("src.ui.theme")
local bars = require("src.ui.components.bars")

local M = {}

function M.draw()
  local p = ctx.get("player")
  if not p then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

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

  -- Status indicators with icons
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)

  -- FPS counter (top-right) - Above minimap
  local fps = love.timer.getFPS()
  local fpsY = 10
  local fpsX = W - 10

  -- Semi-transparent background for FPS counter
  love.graphics.setColor(0.1, 0.15, 0.2, 0.8)
  love.graphics.rectangle("fill", fpsX - 60, fpsY - 5, 60, 25, 2)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
  love.graphics.rectangle("line", fpsX - 60, fpsY - 5, 60, 25, 2)

  -- FPS text
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf(fps .. " FPS", fpsX - 58, fpsY, 56, "center")

  -- Minimap (below FPS counter) - Enhanced with better styling
  local mapSize = 140
  local mapX, mapY = W - mapSize - 10, fpsY + 35

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
  for i = 1, 3 do
    local gx = mapX + (mapSize / 4) * i
    local gy = mapY + (mapSize / 4) * i
    love.graphics.line(gx, mapY, gx, mapY + mapSize)
    love.graphics.line(mapX, gy, mapX + mapSize, gy)
  end

  local gameState = ctx.get("gameState")
  local station = ctx.get("station")
  local enemies = ctx.get("enemies")
  local half = gameState.G.WORLD_SIZE
  local function toMini(wx, wy)
    local u = (wx + half) / (2 * half)
    local v = (wy + half) / (2 * half)
    return mapX + u * mapSize, mapY + v * mapSize
  end

  -- Station marker
  if station then
    local sx, sy = toMini(station.x, station.y)
    love.graphics.setColor(theme.energy[1], theme.energy[2], theme.energy[3], 0.9)
    love.graphics.circle("fill", sx, sy, 4)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", sx, sy, 4)
  end

  -- Enemy markers
  love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
  for _, e in ipairs(enemies or {}) do
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
end

return M
