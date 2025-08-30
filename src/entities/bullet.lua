
local ctx   = require("src.core.ctx")
local util  = require("src.core.util")
local enemy = require("src.entities.enemy")
local bolt  = require("assets.weapons.bolt")

local M = {}

local function newBullet(x,y,vx,vy, life, dmg, owner)
  return {x=x,y=y,vx=vx,vy=vy, life=life, dmg=dmg, owner=owner, radius=3}
end

function M.createFromOwner(owner, spreadMul)
  local s = (owner.spread or 0) * (spreadMul or 1)
  local angle = owner.r + (love.math.random()*2-1) * s
  local spd = owner.bulletSpeed
  local bx = owner.x + math.cos(angle)* (owner.radius+8)
  local by = owner.y + math.sin(angle)* (owner.radius+8)
  local bvx = math.cos(angle)*spd + (owner.vx or 0)*0.3
  local bvy = math.sin(angle)*spd + (owner.vy or 0)*0.3
  table.insert(ctx.bullets, newBullet(bx,by,bvx,bvy, owner.bulletLife, owner.damage, owner))
end

local function hitEnemy(b, eIndex)
  local e = ctx.enemies[eIndex]
  if not e then return end
  enemy.onHit(e, b.dmg)
  for _=1,2 do
    table.insert(ctx.particles, {x=b.x,y=b.y,vx=util.randf(-40,40),vy=util.randf(-40,40),life=util.randf(0.2,0.4)})
  end
  table.remove(ctx.bullets, b._i)
end

local function hitPlayer(b)
  local p = ctx.player
  p.shieldCooldown = p.shieldCDMax
  local s = math.min(p.shield, b.dmg)
  p.shield = p.shield - s
  local dmg = b.dmg - s
  if dmg > 0 then p.hp = p.hp - dmg end
  for _=1,2 do
    table.insert(ctx.particles, {x=b.x,y=b.y,vx=util.randf(-40,40),vy=util.randf(-40,40),life=util.randf(0.2,0.4)})
  end
  table.remove(ctx.bullets, b._i)
  if p.hp <= 0 then
    ctx.camera.shake = 1.0
    for k=1,40 do
      table.insert(ctx.particles, {x=p.x,y=p.y,vx=util.randf(-120,120),vy=util.randf(-120,120),life=util.randf(0.6,1.2)})
    end
    p.x, p.y = ctx.station.x+util.randf(-40,40), ctx.station.y+util.randf(-40,40)
    p.vx, p.vy = 0,0
    p.hp = math.max(30, math.floor(p.maxHP*0.6))
    p.shield = math.max(40, math.floor(p.maxShield*0.6))
    p.energy = p.maxEnergy
  end
end

function M.update(dt)
  for i = #ctx.bullets, 1, -1 do
    local b = ctx.bullets[i]; b._i = i
    b.x = b.x + b.vx*dt
    b.y = b.y + b.vy*dt
    b.life = b.life - dt
    if b.life <= 0 then table.remove(ctx.bullets, i) goto continue end

    if b.owner == ctx.player then
      for j=#ctx.enemies,1,-1 do
        local e = ctx.enemies[j]
        if util.len2(b.x-e.x, b.y-e.y) <= (e.radius+3)*(e.radius+3) then
          hitEnemy(b, j)
          break
        end
      end
    else
      local p = ctx.player
      if util.len2(b.x-p.x, b.y-p.y) <= (p.radius+3)*(p.radius+3) then
        hitPlayer(b)
      end
    end
    ::continue::
  end
end

function M.draw()
  for _,b in ipairs(ctx.bullets) do
    local rot = math.atan2(b.vy, b.vx)
    bolt.draw(b.x, b.y, rot)
  end
end

return M
