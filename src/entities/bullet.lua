local ctx   = require("src.core.ctx")
local util  = require("src.core.util")
local enemy = require("src.entities.enemy")
local bolt  = require("src.content.weapons.bolt")
local rocket= require("src.content.weapons.rocket")

local M = {}

local function newBullet(x,y,vx,vy, life, dmg, owner, weapon)
  return {x=x,y=y,vx=vx,vy=vy, life=life, dmg=dmg, owner=owner, radius=3, weapon=weapon or bolt}
end

function M.createFromOwner(owner, spreadMul, weapon)
  local s = (owner.spread or 0) * (spreadMul or 1)
  local angle = owner.r + (love.math.random()*2-1) * s
  local spd = owner.bulletSpeed
  local bx = owner.x + math.cos(angle)* (owner.radius+8)
  local by = owner.y + math.sin(angle)* (owner.radius+8)
  local bvx = math.cos(angle)*spd + (owner.vx or 0)*0.3
  local bvy = math.sin(angle)*spd + (owner.vy or 0)*0.3
  table.insert(ctx.bullets, newBullet(bx,by,bvx,bvy, owner.bulletLife, owner.damage, owner, weapon))
end

local function hitEnemy(b, eIndex)
  local e = ctx.enemies[eIndex]
  if not e then return end
  
  -- Check shield collision first
  local shieldRadius = e.radius + 8
  local distToCenter = util.len(b.x - e.x, b.y - e.y)
  
  if e.shield > 0 and distToCenter <= shieldRadius then
    -- Hit shield - damage shield and deflect bullet
    e.shieldCooldown = e.shieldCDMax
    local damageToShield = math.min(e.shield, b.dmg)
    e.shield = e.shield - damageToShield
    
    -- Make enemy aggressive when shield is hit
    e.state = "aggro"
    
    -- Create shield impact particles
    for _=1,3 do
      local angle = math.atan2(b.y - e.y, b.x - e.x) + (love.math.random()*2-1)*0.5
      local dist = shieldRadius + love.math.random()*5
      local px = e.x + math.cos(angle) * dist
      local py = e.y + math.sin(angle) * dist
      table.insert(ctx.particles, {x=px, y=py, vx=math.cos(angle)*60, vy=math.sin(angle)*60, life=0.3})
    end
    
    -- Remove bullet after hitting shield
    table.remove(ctx.bullets, b._i)
    return
  end
  
  -- Hit the actual ship if shield is down or bullet penetrates
  enemy.onHit(e, b.dmg)
  for _=1,2 do
    table.insert(ctx.particles, {x=b.x,y=b.y,vx=util.randf(-40,40),vy=util.randf(-40,40),life=util.randf(0.2,0.4)})
  end
  table.remove(ctx.bullets, b._i)
end

local function hitPlayer(b)
  local p = ctx.player
  
  -- Check shield collision first
  local shieldRadius = p.radius + 8
  local distToCenter = util.len(b.x - p.x, b.y - p.y)
  
  if p.shield > 0 and distToCenter <= shieldRadius then
    -- Hit shield - damage shield and deflect bullet
    p.shieldCooldown = p.shieldCDMax
    local damageToShield = math.min(p.shield, b.dmg)
    p.shield = p.shield - damageToShield
    
    -- Make the enemy that fired this bullet aggressive
    if b.owner and b.owner ~= ctx.player then
      enemy.makeAggressive(b.owner)
    end
    
    -- Create shield impact particles
    for _=1,3 do
      local angle = math.atan2(b.y - p.y, b.x - p.x) + (love.math.random()*2-1)*0.5
      local dist = shieldRadius + love.math.random()*5
      local px = p.x + math.cos(angle) * dist
      local py = p.y + math.sin(angle) * dist
      table.insert(ctx.particles, {x=px, y=py, vx=math.cos(angle)*60, vy=math.sin(angle)*60, life=0.3})
    end
    
    -- Remove bullet after hitting shield
    table.remove(ctx.bullets, b._i)
    return
  end
  
  -- Hit the actual ship if shield is down
  p.shieldCooldown = p.shieldCDMax
  local s = math.min(p.shield, b.dmg)
  p.shield = p.shield - s
  local dmg = b.dmg - s
  if dmg > 0 then p.hp = p.hp - dmg end
  
  -- Make the enemy that fired this bullet aggressive
  if b.owner and b.owner ~= ctx.player then
    enemy.makeAggressive(b.owner)
  end
  
  for _=1,2 do
    table.insert(ctx.particles, {x=b.x,y=b.y,vx=util.randf(-40,40),vy=util.randf(-40,40),life=util.randf(0.2,0.4)})
  end
  table.remove(ctx.bullets, b._i)
  if p.hp <= 0 then
    ctx.camera.shake = 1.0
    for k=1,40 do
      table.insert(ctx.particles, {x=p.x,y=p.y,vx=util.randf(-120,120),vy=util.randf(-120,120),life=util.randf(0.6,1.2)})
    end
    -- Respawn at docking area but not docked
    p.x = ctx.station.x + 150  -- Same as initial spawn
    p.y = ctx.station.y
    p.docked = false  -- Ensure not docked
    p.vx, p.vy = 0,0
    p.hp = math.max(30, math.floor(p.maxHP*0.6))
    p.shield = math.max(40, math.floor(p.maxShield*0.6))
    p.energy = p.maxEnergy
  end
end

function M.update(dt)
  for i = #ctx.bullets, 1, -1 do
    local b = ctx.bullets[i]; b._i = i

    -- Homing for rockets
    if b.weapon == rocket and b.target and b.target.hp > 0 then
      local dx = b.target.x - b.x
      local dy = b.target.y - b.y
      local dist = util.len(dx, dy)
      if dist > 0 then
        local spd = 800  -- rocket speed
        b.vx = (dx / dist) * spd
        b.vy = (dy / dist) * spd
      end
    elseif b.weapon == rocket and (not b.target or b.target.hp <= 0) then
      -- Remove rocket if target is dead
      table.remove(ctx.bullets, i)
      goto continue
    end

    -- Homing for enemy bolts
    if b.weapon == bolt and b.target and b.target.hp > 0 then
      local dx = b.target.x - b.x
      local dy = b.target.y - b.y
      local dist = util.len(dx, dy)
      if dist > 0 then
        local spd = b.owner.bulletSpeed  -- Use owner's bullet speed
        b.vx = (dx / dist) * spd
        b.vy = (dy / dist) * spd
      end
    elseif b.weapon == bolt and (not b.target or b.target.hp <= 0) then
      -- Remove bolt if target is dead
      table.remove(ctx.bullets, i)
      goto continue
    end

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
    b.weapon.draw(b.x, b.y, rot)
  end
end

return M
