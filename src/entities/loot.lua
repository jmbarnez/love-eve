
local ctx  = require("src.core.state")
local util = require("src.core.util")

local M = {}

function M.init()
  ctx.set("loots", {})
end

function M.update(dt)
  local loots = ctx.get("loots")
  local player = ctx.get("player")
  local camera = ctx.get("camera")

  for i=#loots,1,-1 do
    local L = loots[i]
    L.life = L.life - dt
    if L.life <= 0 then table.remove(loots, i) goto continue end

    local dx,dy = player.x - L.x, player.y - L.y
    local d2 = util.len2(dx,dy)
    if d2 < 200*200 then
      local d = math.sqrt(d2)
      local ux,uy = (dx/d), (dy/d)
      local pull = util.clamp(2600/d2, 0, 280)
      L.x = L.x + ux * pull * dt
      L.y = L.y + uy * pull * dt
    end
    if util.len2(L.x-player.x, L.y-player.y) <= (player.radius+L.radius)*(player.radius+L.radius) then
      player.credits = player.credits + L.credits
      player.xp = player.xp + L.xp
      -- level up
      while player.xp >= player.xpToNext do
        player.xp = player.xp - player.xpToNext
        player.level = player.level + 1
        player.xpToNext = math.floor(player.xpToNext * 1.35 + 0.5)
        camera.shake = 0.4
        player.maxHP = player.maxHP + 10
        player.hp = player.maxHP
        player.maxShield = player.maxShield + 12
        player.shield = player.maxShield
      end
      camera.shake = math.max(camera.shake, 0.15)
      table.remove(loots, i)
    end
    ::continue::
  end
end

function M.draw()
  local loots = ctx.get("loots")
  local gameState = ctx.get("gameState")

  for _,L in ipairs(loots) do
    love.graphics.setColor(0.9,0.8,0.3,1)
    love.graphics.push(); love.graphics.translate(L.x, L.y); love.graphics.rotate(gameState.t*(L.spin or 1))
    love.graphics.polygon("fill", -8,0, 0,8, 8,0, 0,-8)
    love.graphics.pop()
  end
  love.graphics.setColor(1,1,1,1)
end

return M
