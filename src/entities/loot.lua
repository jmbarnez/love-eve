
local ctx  = require("src.core.ctx")
local util = require("src.core.util")

local M = {}

function M.update(dt)
  for i=#ctx.loots,1,-1 do
    local L = ctx.loots[i]
    L.life = L.life - dt
    if L.life <= 0 then table.remove(ctx.loots, i) goto continue end

    local dx,dy = ctx.player.x - L.x, ctx.player.y - L.y
    local d2 = util.len2(dx,dy)
    if d2 < 200*200 then
      local d = math.sqrt(d2)
      local ux,uy = (dx/d), (dy/d)
      local pull = util.clamp(2600/d2, 0, 280)
      L.x = L.x + ux * pull * dt
      L.y = L.y + uy * pull * dt
    end
    if util.len2(L.x-ctx.player.x, L.y-ctx.player.y) <= (ctx.player.radius+L.radius)*(ctx.player.radius+L.radius) then
      ctx.player.credits = ctx.player.credits + L.credits
      ctx.player.xp = ctx.player.xp + L.xp
      -- level up
      while ctx.player.xp >= ctx.player.xpToNext do
        ctx.player.xp = ctx.player.xp - ctx.player.xpToNext
        ctx.player.level = ctx.player.level + 1
        ctx.player.xpToNext = math.floor(ctx.player.xpToNext * 1.35 + 0.5)
        ctx.camera.shake = 0.4
        ctx.player.maxHP = ctx.player.maxHP + 10
        ctx.player.hp = ctx.player.maxHP
        ctx.player.maxShield = ctx.player.maxShield + 12
        ctx.player.shield = ctx.player.maxShield
      end
      ctx.camera.shake = math.max(ctx.camera.shake, 0.15)
      table.remove(ctx.loots, i)
    end
    ::continue::
  end
end

function M.draw()
  for _,L in ipairs(ctx.loots) do
    love.graphics.setColor(0.9,0.8,0.3,1)
    love.graphics.push(); love.graphics.translate(L.x, L.y); love.graphics.rotate(ctx.state.t*(L.spin or 1))
    love.graphics.polygon("fill", -8,0, 0,8, 8,0, 0,-8)
    love.graphics.pop()
  end
  love.graphics.setColor(1,1,1,1)
end

return M
