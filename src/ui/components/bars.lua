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

function M.eveStyle(x, y, w, h, value, maxValue, color, label)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))

  -- EVE Online-style bar background
  love.graphics.setColor(0.08, 0.12, 0.16, 0.9)
  love.graphics.rectangle("fill", x, y, w, h, 2)

  -- Inner background
  love.graphics.setColor(0.03, 0.06, 0.08, 0.8)
  love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)

  -- Fill bar with gradient effect
  local fillWidth = (w - 4) * pct
  love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 0.9)
  love.graphics.rectangle("fill", x + 2, y + 2, fillWidth, h - 4, 1)

  -- Highlight stripe
  love.graphics.setColor(1, 1, 1, 0.4)
  love.graphics.rectangle("fill", x + 2, y + 2, fillWidth, 3, 1)

  -- Border
  love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h, 2)

  -- Label
  love.graphics.setColor(1, 1, 1, 0.9)
  local font = love.graphics.getFont()
  if label then
    love.graphics.printf(label, x + 4, y + 2, w - 8, "left")
  end

  -- Percentage
  local text = string.format("%.0f%%", pct * 100)
  love.graphics.printf(text, x + 4, y + 2, w - 8, "right")

  -- Critical warning for low values
  if pct < 0.25 and pct > 0 then
    love.graphics.setColor(1, 0.3, 0.2, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2, 2)
  end

  return pct
end

-- New circular progress indicator for more unique styling
function M.circularProgress(x, y, radius, value, maxValue, color, label, thickness)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))
  thickness = thickness or 8

  -- Background circle
  love.graphics.setColor(0.08, 0.12, 0.16, 0.9)
  love.graphics.setLineWidth(thickness)
  love.graphics.circle("line", x, y, radius)

  -- Progress arc
  if pct > 0 then
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.setLineWidth(thickness - 1)

    -- Draw arc from 12 o'clock position
    local startAngle = -math.pi/2
    local endAngle = startAngle + (pct * 2 * math.pi)

    -- Draw the arc segments
    local segments = 32
    local prevX = x + math.cos(startAngle) * radius
    local prevY = y + math.sin(startAngle) * radius

    for i = 1, segments do
      local angle = startAngle + (i / segments) * (pct * 2 * math.pi)
      if angle > endAngle then break end

      local cx = x + math.cos(angle) * radius
      local cy = y + math.sin(angle) * radius

      love.graphics.line(prevX, prevY, cx, cy)
      prevX, prevY = cx, cy
    end
  end

  -- Inner glow effect for critical states
  if pct < 0.25 and pct > 0 then
    love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 0.4)
    love.graphics.setLineWidth(thickness + 2)
    love.graphics.circle("line", x, y, radius + 1)
  end

  -- Label
  love.graphics.setColor(1, 1, 1, 0.9)
  local font = love.graphics.getFont()
  if label then
    love.graphics.printf(label, x - radius, y - radius - 20, radius * 2, "center")
  end

  -- Percentage in center
  local text = string.format("%.0f%%", pct * 100)
  love.graphics.printf(text, x - radius, y - 8, radius * 2, "center")

  return pct
end

-- Configurable ring-style progress with optional label/percent
-- opts: { thickness=8, bgColor={r,g,b,a}, showLabel=false, showPercent=false, labelOffsetY=-20, startAngle=-math.pi/2, sweep=2*math.pi }
function M.ringProgress(x, y, radius, value, maxValue, color, label, opts)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))
  opts = opts or {}
  local thickness = opts.thickness or 8
  local startAngle = opts.startAngle or (-math.pi/2)
  local sweep = opts.sweep or (2 * math.pi)
  local bg = opts.bgColor or {0.08, 0.12, 0.16, 0.9}

  -- Background ring
  love.graphics.setColor(bg[1], bg[2], bg[3], bg[4])
  love.graphics.setLineWidth(thickness)
  love.graphics.circle("line", x, y, radius)

  -- Progress arc
  if pct > 0 then
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.setLineWidth(math.max(1, thickness - 1))

    local endAngle = startAngle + (pct * sweep)
    local segments = 64
    local prevX = x + math.cos(startAngle) * radius
    local prevY = y + math.sin(startAngle) * radius
    for i = 1, segments do
      local angle = startAngle + (i / segments) * (pct * sweep)
      if angle > endAngle then break end
      local cx = x + math.cos(angle) * radius
      local cy = y + math.sin(angle) * radius
      love.graphics.line(prevX, prevY, cx, cy)
      prevX, prevY = cx, cy
    end
  end

  local showLabel = opts.showLabel
  local showPercent = opts.showPercent
  local labelOffsetY = opts.labelOffsetY or -20

  -- Label
  if showLabel and label then
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(label, x - radius, y - radius + labelOffsetY, radius * 2, "center")
  end

  -- Percentage text
  if showPercent then
    love.graphics.setColor(1, 1, 1, 0.95)
    local text = string.format("%.0f%%", pct * 100)
    love.graphics.printf(text, x - radius, y - 8, radius * 2, "center")
  end

  return pct
end

-- Hexagonal progress indicator for a more sci-fi look
function M.hexProgress(x, y, size, value, maxValue, color, label)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))

  -- Draw hexagon background
  love.graphics.setColor(0.08, 0.12, 0.16, 0.9)
  M.drawHexagon(x, y, size)

  -- Fill hexagon based on progress
  if pct > 0 then
    love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 0.9)
    M.drawHexagon(x, y, size * pct)
  end

  -- Border
  love.graphics.setColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 1)
  love.graphics.setLineWidth(2)
  M.drawHexagonOutline(x, y, size)

  -- Label
  love.graphics.setColor(1, 1, 1, 0.9)
  if label then
    love.graphics.printf(label, x - size, y - size - 20, size * 2, "center")
  end

  -- Percentage
  local text = string.format("%.0f%%", pct * 100)
  love.graphics.printf(text, x - size, y - 8, size * 2, "center")

  return pct
end

-- Helper function to draw filled hexagon
function M.drawHexagon(x, y, size)
  local vertices = {}
  for i = 1, 6 do
    local angle = (i - 1) * math.pi / 3
    local vx = x + size * math.cos(angle)
    local vy = y + size * math.sin(angle)
    table.insert(vertices, vx)
    table.insert(vertices, vy)
  end
  love.graphics.polygon("fill", vertices)
end

-- Helper function to draw hexagon outline
function M.drawHexagonOutline(x, y, size)
  local vertices = {}
  for i = 1, 6 do
    local angle = (i - 1) * math.pi / 3
    local vx = x + size * math.cos(angle)
    local vy = y + size * math.sin(angle)
    table.insert(vertices, vx)
    table.insert(vertices, vy)
  end
  -- Close the hexagon
  table.insert(vertices, vertices[1])
  table.insert(vertices, vertices[2])
  love.graphics.line(vertices)
end

-- Radial progress indicator with multiple rings
function M.radialProgress(x, y, innerRadius, outerRadius, value, maxValue, color, label)
  local pct = math.max(0, math.min(1, (maxValue ~= 0 and value / maxValue) or 0))

  -- Background rings
  love.graphics.setColor(0.08, 0.12, 0.16, 0.9)
  love.graphics.setLineWidth(4)
  love.graphics.circle("line", x, y, outerRadius)
  love.graphics.circle("line", x, y, innerRadius)

  -- Progress arc
  if pct > 0 then
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.setLineWidth(6)

    local startAngle = -math.pi/2
    local endAngle = startAngle + (pct * 2 * math.pi)

    -- Draw progress arc
    local segments = 64
    local prevX = x + math.cos(startAngle) * ((innerRadius + outerRadius) / 2)
    local prevY = y + math.sin(startAngle) * ((innerRadius + outerRadius) / 2)

    for i = 1, segments do
      local angle = startAngle + (i / segments) * (pct * 2 * math.pi)
      if angle > endAngle then break end

      local cx = x + math.cos(angle) * ((innerRadius + outerRadius) / 2)
      local cy = y + math.sin(angle) * ((innerRadius + outerRadius) / 2)

      love.graphics.line(prevX, prevY, cx, cy)
      prevX, prevY = cx, cy
    end
  end

  -- Label
  love.graphics.setColor(1, 1, 1, 0.9)
  if label then
    love.graphics.printf(label, x - outerRadius, y - outerRadius - 20, outerRadius * 2, "center")
  end

  -- Percentage
  local text = string.format("%.0f%%", pct * 100)
  love.graphics.printf(text, x - outerRadius, y - 8, outerRadius * 2, "center")

  return pct
end

return M
