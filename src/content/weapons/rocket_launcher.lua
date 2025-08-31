-- Rocket Launcher Weapon Content
-- High damage homing rocket launcher

local M = {}

-- Weapon properties
M.name = "Rocket Launcher"
M.description = "Fires homing rockets that track enemies"
M.type = "rocket"

-- Visual properties (similar to enemy bolts but bigger)
M.color = {1, 0.5, 0, 1}  -- Orange
M.shape = "rocket"
M.size = {width = 12, height = 6}

-- Combat properties
M.damage = 45
M.speed = 600
M.lifetime = 8.0
M.fireRate = 1.5
M.radius = 4
M.homingRange = 500

-- Visual rendering function (rocket-like projectile similar to enemy bolts)
function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  
  -- Main rocket body (similar to bolt but larger)
  love.graphics.setColor(M.color)
  love.graphics.polygon("fill", 8, 0, -6, 4, -6, -4)  -- Larger triangle
  
  -- Rocket fins
  love.graphics.setColor(0.8, 0.3, 0.1, 1)  -- Darker orange
  love.graphics.polygon("fill", -6, 4, -8, 6, -8, 2)  -- Top fin
  love.graphics.polygon("fill", -6, -4, -8, -6, -8, -2)  -- Bottom fin
  
  -- Exhaust trail
  love.graphics.setColor(1, 1, 0.2, 0.6)  -- Yellow exhaust
  love.graphics.polygon("fill", -6, 2, -10, 1, -10, -1, -6, -2)
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

-- Impact particles
function M.onImpact(x, y)
  return {
    particles = {
      {x = x, y = y, vx = 0, vy = 0, life = 0.8, color = {1, 0.5, 0, 1}, size = 5},
      {x = x, y = y, vx = 80, vy = 0, life = 0.5, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = -80, vy = 0, life = 0.5, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = 0, vy = 80, life = 0.5, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = 0, vy = -80, life = 0.5, color = {1, 0.8, 0, 0.8}}
    }
  }
end

return M