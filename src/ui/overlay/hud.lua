local ctx = require("src.core.state")
local theme = require("src.ui.theme")
local bars = require("src.ui.components.bars")

local M = {}

function M.draw()
  if not ctx.player then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local p = ctx.player

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
end

return M

