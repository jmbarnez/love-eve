
-- Vector-based starter ship model (no external assets).
-- Layers: hull, wings, cockpit, engine pods, and animated thruster.

local thruster = require("assets.effects.thruster")

local M = {}

local function drawHull()
  love.graphics.setColor(0.18, 0.72, 1.0, 1) -- main hull
  love.graphics.polygon("fill",
    24,0,   -16,12,  -10,6,  -14,2,  -14,-2,  -10,-6,  -16,-12
  )
  love.graphics.setColor(1,1,1,0.08)
  love.graphics.circle("line", 0,0, 18)
end

local function drawWings()
  love.graphics.setColor(0.12, 0.45, 0.8, 1)
  love.graphics.polygon("fill", 2,10, -18,18, -8,8)
  love.graphics.polygon("fill", 2,-10, -18,-18, -8,-8)
end

local function drawCockpit()
  love.graphics.setColor(0.75,0.95,1,1)
  love.graphics.circle("fill", 2,0, 5)
end

local function drawEngines()
  love.graphics.setColor(0.75,0.95,1,1)
  love.graphics.circle("line", -10, 6, 3)
  love.graphics.circle("line", -10,-6, 3)
end

function M.draw(x,y,rot,scale,speedRatio)
  scale = scale or 1.0
  love.graphics.push()
  love.graphics.translate(x,y)
  love.graphics.rotate(rot or 0)
  love.graphics.scale(scale, scale)

  drawWings()
  drawHull()
  drawCockpit()
  drawEngines()

  -- Thruster intensity based on ship speed
  local strength = math.max(0, math.min(1, (speedRatio or 0)))
  thruster.draw(-14, 0, rot or 0, strength)

  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)
end

return M
