-- Starter Ship Content
-- Contains all data and behavior for the basic starter ship

local M = {}

-- Ship properties
M.name = "Starter Frigate"
M.description = "Basic frigate with balanced combat capabilities"
M.type = "frigate"
M.class = "starter"

-- Combat stats
M.maxHP = 100
M.maxShield = 120
M.maxEnergy = 100

-- Movement properties
M.accel = 120
M.maxSpeed = 300
M.friction = 1.0

-- Combat properties
M.damage = 16
M.bulletSpeed = 560
M.bulletLife = 1.2
M.spread = 0.06

-- Visual properties
M.scale = 1.0
M.radius = 14

-- Ship appearance data
M.colors = {
  hull = {0.25, 0.35, 0.6, 1},      -- darker metallic blue
  hullDetail = {0.35, 0.45, 0.7, 1}, -- lighter blue for details
  wings = {0.2, 0.3, 0.55, 1},      -- darker wing color
  wingDetail = {0.3, 0.4, 0.65, 1}, -- lighter wing detail
  cockpit = {0.15, 0.25, 0.45, 1},  -- cockpit frame
  canopy = {0.8, 0.9, 1.0, 0.4},    -- transparent canopy
  engines = {0.1, 0.1, 0.1, 1},     -- engine housings
  details = {0.3, 0.3, 0.3, 1}      -- various details
}

-- Hull drawing function
local function drawHull()
  love.graphics.setColor(M.colors.hull)
  love.graphics.polygon("fill",
    24,0,   -16,10,  -12,6,  -18,2,  -18,-2,  -12,-6,  -16,-10
  )

  love.graphics.setColor(M.colors.hullDetail)
  love.graphics.polygon("line",
    24,0,   -16,10,  -12,6,  -18,2,  -18,-2,  -12,-6,  -16,-10
  )

  love.graphics.setColor(M.colors.hullDetail[1], M.colors.hullDetail[2], M.colors.hullDetail[3], 0.8)
  love.graphics.line(-16,10, -16,-10)
  love.graphics.line(-12,6, -12,-6)
  love.graphics.line(-18,2, -18,-2)
end

-- Wings drawing function
local function drawWings()
  love.graphics.setColor(M.colors.wings)
  love.graphics.polygon("fill", 2,12, -20,16, -14,11, -8,12)
  love.graphics.polygon("fill", 2,-12, -20,-16, -14,-11, -8,-12)

  love.graphics.setColor(M.colors.wingDetail)
  love.graphics.polygon("line", 2,12, -20,16, -14,11, -8,12)
  love.graphics.polygon("line", 2,-12, -20,-16, -14,-11, -8,-12)

  -- Weapon hardpoints
  love.graphics.setColor(0.1, 0.1, 0.1, 1)
  love.graphics.circle("fill", -6, 14, 1.5)  -- top wing turret
  love.graphics.circle("fill", -6, -14, 1.5) -- bottom wing turret
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.circle("line", -6, 14, 1.5)
  love.graphics.circle("line", -6, -14, 1.5)
end

-- Cockpit drawing function
local function drawCockpit()
  love.graphics.setColor(M.colors.cockpit)
  love.graphics.polygon("fill", 8,4, 16,6, 20,4, 16,2, 8,2)
  love.graphics.polygon("fill", 8,-4, 16,-6, 20,-4, 16,-2, 8,-2)

  love.graphics.setColor(M.colors.canopy)
  love.graphics.polygon("fill", 10,3, 18,5, 18,1, 10,1)
  love.graphics.polygon("fill", 10,-3, 18,-5, 18,-1, 10,-1)

  love.graphics.setColor(M.colors.hullDetail)
  love.graphics.polygon("line", 8,4, 16,6, 20,4, 16,2, 8,2)
  love.graphics.polygon("line", 8,-4, 16,-6, 20,-4, 16,-2, 8,-2)
end

-- Engines drawing function
local function drawEngines()
  love.graphics.setColor(M.colors.engines)
  love.graphics.circle("fill", -12, 6, 4)
  love.graphics.circle("fill", -12, -6, 4)

  love.graphics.setColor(0.05, 0.05, 0.05, 1)
  love.graphics.circle("fill", -12, 6, 2.5)
  love.graphics.circle("fill", -12, -6, 2.5)

  love.graphics.setColor(0.4, 0.4, 0.4, 1)
  love.graphics.circle("line", -12, 6, 4)
  love.graphics.circle("line", -12, -6, 4)
  love.graphics.circle("line", -12, 6, 2.5)
  love.graphics.circle("line", -12, -6, 2.5)

  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", -16, 4, 2, 4)
  love.graphics.rectangle("fill", -16, -8, 2, 4)
end

-- Details drawing function
local function drawDetails()
  love.graphics.setColor(M.colors.details)
  love.graphics.circle("fill", 6, 0, 1)
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.circle("line", 6, 0, 1)

  love.graphics.setColor(0.4, 0.4, 0.4, 1)
  love.graphics.line(8, 0, 12, 0)
  love.graphics.circle("fill", 12, 0, 0.5)

  love.graphics.setColor(0.5, 0.5, 0.7, 0.6)
  love.graphics.line(-8, 8, -8, -8)
  love.graphics.line(-4, 6, -4, -6)
end

-- Main draw function
function M.draw(x, y, rot, scale, speedRatio)
  scale = scale or M.scale
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.scale(scale, scale)

  drawWings()
  drawHull()
  drawCockpit()
  drawEngines()
  drawDetails()

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

-- Ship behavior functions
function M.getWeaponOffset()
  return {x = 0, y = 0}  -- Center of ship
end

function M.getEngineGlow(speedRatio)
  speedRatio = speedRatio or 0
  return {
    intensity = speedRatio * 0.8,
    color = {0.8, 0.9, 1.0, 1}
  }
end

return M
