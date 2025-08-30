
local M = {}

function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(1,1,1,1)
  love.graphics.polygon("fill", 4,0, -3,2, -3,-2)
  love.graphics.pop()
end

return M
