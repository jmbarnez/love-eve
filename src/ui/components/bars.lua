local theme = require("src.ui.theme")

local M = {}

function M.sciFi(x, y, w, h, value, maxValue, color, label, showPercentage)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))

  -- Outer glow effect for critical states
  if pct < 0.25 and pct > 0 then
    love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 0.3)
    love.graphics.rectangle("fill", x - 2, y - 2, w + 4, h + 4, 5)
  end

  -- Main background with sci-fi border
  love.graphics.setColor(0.05, 0.08, 0.12, 0.9)
  love.graphics.rectangle("fill", x, y, w, h, 3)

  -- Inner glow effect
  love.graphics.setColor(color[1] * 0.1, color[2] * 0.1, color[3] * 0.1, 0.4)
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 2)

  -- Fill bar with gradient effect
  if pct > 0 then
    -- Main fill
    love.graphics.setColor(color[1], color[2], color[3], 0.8)
    love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * pct, h - 4, 1)

    -- Highlight stripe
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * pct, 2, 1)

    -- Bottom shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 2, y + h - 4, (w - 4) * pct, 2, 1)

    -- Animated energy flow effect
    if pct > 0.1 then
      local time = love.timer.getTime()
      local flowOffset = (time * 50) % ((w - 4) * pct)
      local flowX = x + 2 + flowOffset
      local flowW = math.min(15, (w - 4) * pct * 0.2)
      if flowX + flowW > x + 2 + (w - 4) * pct then
        flowW = x + 2 + (w - 4) * pct - flowX
      end
      love.graphics.setColor(color[1] * 1.3, color[2] * 1.3, color[3] * 1.3, 0.7)
      love.graphics.rectangle("fill", flowX, y + 2, flowW, h - 4, 1)
    end
  end

  -- Border with sci-fi styling
  love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h, 3)

  -- Inner border
  love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 0.8)
  love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, 2)

  -- Corner accents
  love.graphics.setColor(color[1] * 0.9, color[2] * 0.9, color[3] * 0.9, 0.6)
  love.graphics.rectangle("fill", x, y, 4, 4)
  love.graphics.rectangle("fill", x + w - 4, y, 4, 4)
  love.graphics.rectangle("fill", x, y + h - 4, 4, 4)
  love.graphics.rectangle("fill", x + w - 4, y + h - 4, 4, 4)

  -- Label and percentage
  love.graphics.setColor(1, 1, 1, 0.9)
  local font = love.graphics.getFont()

  if label then
    love.graphics.printf(label, x + 8, y + 3, w - 16, "left")
  end

  if showPercentage then
    local text = string.format("%.0f%%", pct * 100)
    love.graphics.printf(text, x + 8, y + 3, w - 16, "right")
  end

  -- Critical warning for low values
  if pct < 0.25 and pct > 0 then
    love.graphics.setColor(1, 0.3, 0.2, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2, 3)
  end
end

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

