local M = {}

function M.draw(x, y, rot)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot or 0)
  love.graphics.setColor(1,0.5,0,1)  -- orange for rocket
  love.graphics.polygon("fill", 6,0, -4,3, -4,-3)  -- larger triangle
  love.graphics.setColor(1,1,1,1)
  love.graphics.pop()
end

return M
