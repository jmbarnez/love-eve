
-- Vector-based starter ship model (no external assets).
-- Layers: hull, wings, cockpit, engine pods, and animated thruster.

local thruster = require("assets.effects.thruster")

local M = {}

local function drawHull()
  -- Main hull - sleek frigate design
  love.graphics.setColor(0.25, 0.35, 0.6, 1) -- darker metallic blue
  love.graphics.polygon("fill",
    24,0,   -16,10,  -12,6,  -18,2,  -18,-2,  -12,-6,  -16,-10
  )

  -- Hull armor plating details
  love.graphics.setColor(0.35, 0.45, 0.7, 1)
  love.graphics.polygon("line",
    24,0,   -16,10,  -12,6,  -18,2,  -18,-2,  -12,-6,  -16,-10
  )

  -- Hull reinforcement lines
  love.graphics.setColor(0.4, 0.5, 0.8, 0.8)
  love.graphics.line(-16,10, -16,-10)
  love.graphics.line(-12,6, -12,-6)
  love.graphics.line(-18,2, -18,-2)
end

local function drawWings()
  -- Main wings with weapon hardpoints
  love.graphics.setColor(0.2, 0.3, 0.55, 1)
  love.graphics.polygon("fill", 2,12, -20,16, -14,11, -8,12)
  love.graphics.polygon("fill", 2,-12, -20,-16, -14,-11, -8,-12)

  -- Wing armor plating
  love.graphics.setColor(0.3, 0.4, 0.65, 1)
  love.graphics.polygon("line", 2,12, -20,16, -14,11, -8,12)
  love.graphics.polygon("line", 2,-12, -20,-16, -14,-11, -8,-12)

  -- Weapon hardpoints (small turrets)
  love.graphics.setColor(0.1, 0.1, 0.1, 1)
  love.graphics.circle("fill", -6, 14, 1.5)  -- top wing turret
  love.graphics.circle("fill", -6, -14, 1.5) -- bottom wing turret
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.circle("line", -6, 14, 1.5)
  love.graphics.circle("line", -6, -14, 1.5)
end

local function drawCockpit()
  -- Detailed cockpit module
  love.graphics.setColor(0.15, 0.25, 0.45, 1) -- cockpit frame
  love.graphics.polygon("fill", 8,4, 16,6, 20,4, 16,2, 8,2)
  love.graphics.polygon("fill", 8,-4, 16,-6, 20,-4, 16,-2, 8,-2)

  -- Cockpit canopy
  love.graphics.setColor(0.8, 0.9, 1.0, 0.4) -- transparent canopy
  love.graphics.polygon("fill", 10,3, 18,5, 18,1, 10,1)
  love.graphics.polygon("fill", 10,-3, 18,-5, 18,-1, 10,-1)

  -- Cockpit frame details
  love.graphics.setColor(0.4, 0.5, 0.7, 1)
  love.graphics.polygon("line", 8,4, 16,6, 20,4, 16,2, 8,2)
  love.graphics.polygon("line", 8,-4, 16,-6, 20,-4, 16,-2, 8,-2)
end

local function drawEngines()
  -- Twin engine assemblies with detail
  love.graphics.setColor(0.1, 0.1, 0.1, 1) -- engine housings
  love.graphics.circle("fill", -12, 6, 4)
  love.graphics.circle("fill", -12, -6, 4)

  -- Engine nozzles
  love.graphics.setColor(0.05, 0.05, 0.05, 1)
  love.graphics.circle("fill", -12, 6, 2.5)
  love.graphics.circle("fill", -12, -6, 2.5)

  -- Engine detail rings
  love.graphics.setColor(0.4, 0.4, 0.4, 1)
  love.graphics.circle("line", -12, 6, 4)
  love.graphics.circle("line", -12, -6, 4)
  love.graphics.circle("line", -12, 6, 2.5)
  love.graphics.circle("line", -12, -6, 2.5)

  -- Engine vents
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", -16, 4, 2, 4)
  love.graphics.rectangle("fill", -16, -8, 2, 4)
end

local function drawDetails()
  -- Ship systems and equipment
  love.graphics.setColor(0.3, 0.3, 0.3, 1)
  -- Sensor array
  love.graphics.circle("fill", 6, 0, 1)
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.circle("line", 6, 0, 1)

  -- Antenna
  love.graphics.setColor(0.4, 0.4, 0.4, 1)
  love.graphics.line(8, 0, 12, 0)
  love.graphics.circle("fill", 12, 0, 0.5)

  -- Armor plating seams
  love.graphics.setColor(0.5, 0.5, 0.7, 0.6)
  love.graphics.line(-8, 8, -8, -8)
  love.graphics.line(-4, 6, -4, -6)
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
  drawDetails()

  -- Thruster intensity based on ship speed
  local strength = math.max(0, math.min(1, (speedRatio or 0)))
  thruster.draw(-14, 0, rot or 0, strength)

  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)
end

return M
