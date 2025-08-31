-- Basic Bolt Weapon Content
-- Contains all data and behavior for the basic bolt projectile

local M = {}

-- Weapon properties
M.name = "Basic Bolt"
M.description = "Standard energy bolt weapon"
M.type = "projectile"

-- Visual properties
M.color = {1, 1, 1, 1}  -- White
M.shape = "triangle"
M.size = {width = 7, height = 4}

-- Combat properties
M.damage = 16
M.speed = 380
M.lifetime = 1.2
M.fireRate = 0.9

-- Visual rendering function
function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(M.color)
  love.graphics.polygon("fill", 4,0, -3,2, -3,-2)
  love.graphics.pop()
end

-- Optional: particle effects on impact
function M.onImpact(x, y)
  -- Could add particle effects here
  return {
    particles = {
      {x = x, y = y, vx = 0, vy = 0, life = 0.3, color = {1, 1, 1, 0.8}}
    }
  }
end

return M
