-- Rocket Weapon Content
-- Contains all data and behavior for the rocket projectile

local M = {}

-- Weapon properties
M.name = "Rocket"
M.description = "Homing rocket with explosive damage"
M.type = "homing_projectile"

-- Visual properties
M.color = {1, 0.5, 0, 1}  -- Orange
M.shape = "triangle"
M.size = {width = 10, height = 6}

-- Combat properties
M.damage = 16
M.speed = 800
M.lifetime = 5.0
M.fireRate = 2.0
M.homingRange = 300

-- Visual rendering function
function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(M.color)
  love.graphics.polygon("fill", 6,0, -4,3, -4,-3)  -- larger triangle
  love.graphics.setColor(1,1,1,1)
  love.graphics.pop()
end

-- Optional: particle effects on impact
function M.onImpact(x, y)
  -- Rocket explosion effect
  return {
    particles = {
      {x = x, y = y, vx = 0, vy = 0, life = 0.5, color = {1, 0.5, 0, 1}, size = 3},
      {x = x, y = y, vx = 50, vy = 0, life = 0.3, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = -50, vy = 0, life = 0.3, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = 0, vy = 50, life = 0.3, color = {1, 0.8, 0, 0.8}},
      {x = x, y = y, vx = 0, vy = -50, life = 0.3, color = {1, 0.8, 0, 0.8}}
    }
  }
end

-- Homing behavior
function M.updateHoming(bullet, target, dt)
  if not target or target.hp <= 0 then return end

  local dx = target.x - bullet.x
  local dy = target.y - bullet.y
  local dist = math.sqrt(dx*dx + dy*dy)

  if dist > 0 then
    -- Smooth homing towards target
    local targetVx = (dx / dist) * M.speed
    local targetVy = (dy / dist) * M.speed

    bullet.vx = bullet.vx + (targetVx - bullet.vx) * 0.8 * dt
    bullet.vy = bullet.vy + (targetVy - bullet.vy) * 0.8 * dt
  end
end

return M
