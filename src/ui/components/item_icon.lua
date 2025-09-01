local items = require("src.content.items.registry")

local M = {}

function M.draw(itemType, x, y, size)
  local color = items.getColor(itemType)
  love.graphics.push()
  love.graphics.translate(x, y)

  if itemType == "rockets" then
    love.graphics.setColor(color)
    love.graphics.polygon("fill", 0, -size/2, -size/3, size/2, size/3, size/2)
    love.graphics.setColor(1, 0.5, 0, 1)
    love.graphics.polygon("fill", -size/6, size/2, 0, size/2 + size/4, size/6, size/2)
  elseif itemType == "energy_cells" then
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -size/3, -size/2, size/3, size)
    love.graphics.rectangle("fill", -size/6, -size/2 - size/8, size/6, size/8)
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4])
    love.graphics.rectangle("fill", -size/4, -size/3, size/4, size/3)
  elseif itemType == "alien_tech" then
    love.graphics.setColor(color)
    love.graphics.circle("fill", 0, 0, size/3)
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4])
    love.graphics.circle("fill", -size/4, -size/4, size/6)
    love.graphics.circle("fill", size/4, -size/4, size/6)
    love.graphics.circle("fill", 0, size/4, size/6)
    love.graphics.setLineWidth(2)
    love.graphics.line(-size/4, -size/4, size/4, -size/4)
    love.graphics.line(0, -size/4, 0, size/4)
  elseif itemType == "repair_kit" then
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -size/8, -size/2, size/4, size)
    love.graphics.rectangle("fill", -size/2, -size/8, size, size/4)
  elseif itemType == "shield_booster" then
    love.graphics.setColor(color)
    love.graphics.polygon("fill", 0, -size/2, -size/3, -size/4, -size/3, size/3, 0, size/2, size/3, size/3, size/3, -size/4)
  elseif itemType == "energy_drink" then
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -size/6, -size/2, size/3, size * 0.8)
    love.graphics.rectangle("fill", -size/8, -size/2 - size/8, size/4, size/8)
  elseif itemType == "quantum_core" then
    local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 4)
    love.graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * pulse)
    love.graphics.circle("fill", 0, 0, size/3 * pulse)
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", 0, 0, size/2)
  elseif itemType == "neural_implant" then
    love.graphics.setColor(color)
    love.graphics.circle("fill", -size/6, -size/6, size/4)
    love.graphics.circle("fill", size/6, -size/6, size/4)
    love.graphics.rectangle("fill", -size/4, 0, size/2, size/3)
  elseif itemType == "basic_turret" then
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -size/4, -size/4, size/2, size/2)
    love.graphics.rectangle("fill", -size/8, -size/2, size/4, size/2)
  else
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", -size/2, -size/2, size, size)
    love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4] or 1)
    love.graphics.rectangle("line", -size/2, -size/2, size, size)
  end

  love.graphics.pop()
end

return M
