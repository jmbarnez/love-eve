local theme = require("src.ui.theme")
local config = require("src.core.config")

local M = {}

-- Base bar drawing function to reduce duplication
local function drawBaseBar(x, y, w, h, value, maxValue, color, style)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))
  local uiConfig = config.ui

  -- Style-specific background
  if style == "sciFi" then
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
  else
    -- Compact/Target style background
    love.graphics.setColor(theme.bg)
    love.graphics.rectangle("fill", x, y, w, h, 2)

    love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.6)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)
  end

  -- Fill bar
  love.graphics.setColor(color[1], color[2], color[3], 0.8)
  love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * pct, h - 4, style == "sciFi" and 1 or 1)

  -- Style-specific effects
  if style == "sciFi" then
    -- Highlight stripe
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * pct, 2, 1)

    -- Bottom shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 2, y + h - 4, (w - 4) * pct, 2, 1)



    -- Border with sci-fi styling
    love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 3)

    -- Inner border
    love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 0.8)
    love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, 2)
  else
    -- Compact/Target border
    love.graphics.setColor(theme.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 2)
  end

  -- Critical warning for low values (sciFi style only)
  if style == "sciFi" and pct < 0.25 and pct > 0 then
    love.graphics.setColor(1, 0.3, 0.2, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2, 3)
  end

  return pct
end

function M.sciFi(x, y, w, h, value, maxValue, color, label, showPercentage)
  local pct = drawBaseBar(x, y, w, h, value, maxValue, color, "sciFi")

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
end

function M.compact(x, y, w, h, value, maxValue, color)
  drawBaseBar(x, y, w, h, value, maxValue, color, "compact")

  local font = love.graphics.getFont()
  love.graphics.setColor(1, 1, 1, 0.8)
  local text = string.format("%.0f%%", drawBaseBar(x, y, w, h, value, maxValue, color, "compact") * 100)
  local textW = font:getWidth(text)
  if textW < w - 4 then
    love.graphics.printf(text, x, y + 1, w, "center")
  end
end

function M.target(x, y, w, h, value, maxValue, color)
  drawBaseBar(x, y, w, h, value, maxValue, color, "target")

  love.graphics.setColor(1, 1, 1, 0.9)
  local text = string.format("%.0f%%", drawBaseBar(x, y, w, h, value, maxValue, color, "target") * 100)
  love.graphics.printf(text, x, y + 1, w, "center")
end

return M
