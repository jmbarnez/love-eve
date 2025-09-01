-- Kinetic Slug Weapon Content
local M = {}

M.name = "Kinetic Slug"
M.description = "A high-velocity kinetic slug."
M.type = "kinetic"

-- Visual properties
M.color = {0.8, 0.8, 0.9, 1}  -- Light grey
M.shape = "rectangle"
M.size = {width = 8, height = 3}

-- Combat properties
M.damage = 15
M.speed = 450
M.lifetime = 1.2

-- Visual rendering function
function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(M.color)
  love.graphics.rectangle("fill", -M.size.width / 2, -M.size.height / 2, M.size.width, M.size.height)
  love.graphics.pop()
end

return M
