local theme = require("src.ui.theme")

local M = {}

function M.compact(x, y, w, h, value, maxValue, color)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))
  love.graphics.setColor(theme.bg)
  love.graphics.rectangle("fill", x, y, w, h, 2)

  love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.6)
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)

  love.graphics.setColor(color[1], color[2], color[3], 0.9)
  love.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * pct, h - 2, 1)

  if pct > 0 then
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", x + 2, y + 2, math.max(1, (w - 4) * pct), 1)
  end

  love.graphics.setColor(theme.border)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h, 2)

  local font = love.graphics.getFont()
  love.graphics.setColor(1, 1, 1, 0.8)
  local text = string.format("%.0f%%", pct * 100)
  local textW = font:getWidth(text)
  if textW < w - 4 then
    love.graphics.printf(text, x, y + 1, w, "center")
  end
end

function M.target(x, y, w, h, value, maxValue, color)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))
  love.graphics.setColor(theme.bg)
  love.graphics.rectangle("fill", x, y, w, h, 2)

  love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.6)
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)

  love.graphics.setColor(color[1], color[2], color[3], 0.9)
  love.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * pct, h - 2, 1)

  love.graphics.setColor(theme.border)
  love.graphics.rectangle("line", x, y, w, h, 2)

  love.graphics.setColor(1, 1, 1, 0.9)
  local text = string.format("%.0f%%", pct * 100)
  love.graphics.printf(text, x, y + 1, w, "center")
end

return M

