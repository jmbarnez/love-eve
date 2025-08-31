-- Generic shield visualization system
local M = {}

-- Draw a simple shield ring if the entity recently took shield damage or its shield is revealed.
-- The shield remains visible once revealed until the shield is fully depleted.
function M.draw(entity)
  if not entity then return end
  if entity.shield and entity.shield > 0 and entity.shieldVisible then
    local r = (entity.radius or 14) + 8
    -- alpha proportional to remaining shield percentage, clamped
    local pct = 0
    if entity.maxShield and entity.maxShield > 0 then
      pct = math.max(0, math.min(1, entity.shield / entity.maxShield))
    else
      pct = 1
    end
    local alpha = 0.2 + 0.5 * pct
    love.graphics.setColor(0.3, 0.8, 1.0, alpha)
    love.graphics.circle("line", entity.x, entity.y, r)
    love.graphics.setColor(1,1,1,1)
  end
end

return M
