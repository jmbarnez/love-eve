-- Basic Bullet Weapon Content
-- Contains all data and behavior for the basic bullet projectile

local M = {}

-- Weapon properties
M.name = "Basic Bullet"
M.description = "Standard physical bullet weapon"
M.type = "bullet"

-- Visual properties
M.color = {0.8, 0.8, 0.8, 1}  -- Gray
M.shape = "circle"
M.size = {radius = 2}

-- Combat properties
M.speed = 500
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
  local particles = {}
  for i = 1, 8 do
    table.insert(particles, {
      x = x,
      y = y,
      vx = (math.random() - 0.5) * 150,
      vy = (math.random() - 0.5) * 150,
      life = math.random() * 0.3 + 0.2,
      color = {0.9, 0.9, 0.7, 1},
      size = math.random() * 2 + 1
    })
  end
  return { particles = particles }
end

return M
