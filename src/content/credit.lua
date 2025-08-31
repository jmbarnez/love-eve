-- Credit Icon Content
-- Contains the visual representation for the credit currency icon

local M = {}

-- Icon properties
M.name = "Credit"
M.description = "In-game currency icon"
M.type = "icon"
M.size = 16  -- Default size in pixels

-- Visual properties
M.colors = {
  outer = {0.9, 0.8, 0.6, 1},    -- Gold color
  inner = {0.95, 0.85, 0.65, 1},  -- Lighter gold
  rim = {0.7, 0.6, 0.4, 1},      -- Darker gold for rim
  symbol = {0.1, 0.1, 0.1, 1}     -- Dark color for symbol
}

-- Main draw function
function M.draw(x, y, size)
  size = size or M.size
  local radius = size / 2
  local innerRadius = radius * 0.7

  love.graphics.push()
  love.graphics.translate(x + radius, y + radius)

  -- Outer rim
  love.graphics.setColor(M.colors.rim)
  love.graphics.circle("fill", 0, 0, radius)

  -- Inner gold area
  love.graphics.setColor(M.colors.outer)
  love.graphics.circle("fill", 0, 0, radius * 0.95)

  -- Inner highlight
  love.graphics.setColor(M.colors.inner)
  love.graphics.circle("fill", 0, 0, innerRadius)

  -- Credit symbol (simple "C")
  love.graphics.setColor(M.colors.symbol)
  love.graphics.setLineWidth(2)
  love.graphics.arc("line", "open", 0, 0, innerRadius * 0.8, -math.pi/2, math.pi/2)

  -- Small line for the "C" bottom
  love.graphics.line(
    -innerRadius * 0.8 * math.cos(math.pi/2),
    innerRadius * 0.8 * math.sin(math.pi/2),
    -innerRadius * 0.8 * math.cos(math.pi/2) + innerRadius * 0.3,
    innerRadius * 0.8 * math.sin(math.pi/2)
  )

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setLineWidth(1)
end

return M
