-- Basic Bullet Weapon Content
-- Contains all data and behavior for the basic bullet projectile

local M = {}

-- Weapon properties
M.name = "Basic Bullet"
M.description = "Standard physical bullet weapon"
M.type = "bullet"

-- Visual properties
M.color = {0.9, 0.8, 0.2, 1}  -- Yellowish bullet
M.shape = "circle"
M.size = {radius = 3}

-- Combat properties
M.damage = 12
M.speed = 336
M.lifetime = 1.5
M.fireRate = 0.5  -- One shot every 2 seconds

-- Visual rendering function
function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(M.color)
  love.graphics.circle("fill", 0, 0, M.size.radius)
  love.graphics.setColor(0.7, 0.6, 0.1, 1)  -- Darker outline
  love.graphics.circle("line", 0, 0, M.size.radius)
  love.graphics.pop()
end

-- Optional: particle effects on impact
function M.onImpact(x, y)
  -- Could add particle effects here
  return {
    particles = {
      {x = x, y = y, vx = 0, vy = 0, life = 0.2, color = {0.9, 0.8, 0.2, 0.6}}
    }
  }
end

return M
