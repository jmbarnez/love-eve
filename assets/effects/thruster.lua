
-- Simple procedural engine exhaust drawn behind the ship.
local M = {}

function M.draw(x, y, rot, strength)
  strength = math.max(0, math.min(1, strength or 0))
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rot + math.pi) -- exhaust points backwards

  local len = 12 + 22*strength
  local w   = 5 + 4*strength

  love.graphics.setColor(1, 0.8, 0.2, 0.8)
  love.graphics.polygon("fill", 0,0,  -len, -w,  -len*0.9, 0,  -len, w)
  love.graphics.setColor(0.9, 0.4, 0.2, 0.6)
  love.graphics.polygon("fill", 0,0,  -len*0.7, -w*0.6,  -len*0.6, 0,  -len*0.7, w*0.6)

  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)
end

return M
