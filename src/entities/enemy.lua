
local ctx    = require("src.core.ctx")
local util   = require("src.core.util")
local bolt   = require("src.content.weapons.bolt")

local M = {}
local respawnTimer = 0

local function preset(level)
  local tier = math.min(1+math.floor((level-1)/3), 4)
  local presets = {
    [1] = {hp=40, shield=30, speed=300, damage=10, fireRate=0.9, range=520, bonus= {xp=20, cr=30}},
    [2] = {hp=70, shield=60, speed=350, damage=12, fireRate=1.2, range=640, bonus= {xp=30, cr=45}},
    [3] = {hp=110, shield=90, speed=400, damage=16, fireRate=1.6, range=700, bonus= {xp=40, cr=65}},
    [4] = {hp=160, shield=140, speed=450, damage=20, fireRate=2.0, range=760, bonus= {xp=55, cr=90}},
  }
  return presets[tier]
end

function M.new(px,py, level)
  local p = preset(level)
  return {
    x=px, y=py, vx=0, vy=0, r=0, radius=12,
    hp=p.hp, maxHP=p.hp,
    shield=p.shield, maxShield=p.shield, shieldRegen=6, shieldCooldown=0, shieldCDMax=2.4,
    accel=200, maxSpeed=p.speed, friction=1.0,
    damage=p.damage, fireRate=p.fireRate, bulletSpeed=380, bulletLife=1.2,
    spread=0.07, lastShot=0, range=p.range,
    bonus=p.bonus,
    state="idle", -- becomes "aggro" only when attacked
  }
end

function M.init() end

local function keepInWorld(e)
  local W = ctx.G.WORLD_SIZE
  if e.x < -W then e.x = -W; e.vx = math.abs(e.vx) end
  if e.x > W then e.x = W; e.vx = -math.abs(e.vx) end
  if e.y < -W then e.y = -W; e.vy = math.abs(e.vy) end
  if e.y > W then e.y = W; e.vy = -math.abs(e.vy) end
end

local function idleWander(e, dt)
  local jitterX = (love.math.random()*2-1) * 0.5
  local jitterY = (love.math.random()*2-1) * 0.5
  e.vx = e.vx + jitterX * 10 * dt
  e.vy = e.vy + jitterY * 10 * dt
  e.x  = e.x + e.vx*dt
  e.y  = e.y + e.vy*dt
  e.r  = e.r + (love.math.random()*2-1)*0.5*dt
end

-- local bullet factory to avoid circular require
local function fire(owner)
  local s = (owner.spread or 0)
  local angle = owner.r + (love.math.random()*2-1) * s
  local spd = owner.bulletSpeed
  local bx = owner.x + math.cos(angle)*(owner.radius+8)
  local by = owner.y + math.sin(angle)*(owner.radius+8)
  local bvx = math.cos(angle)*spd + (owner.vx or 0)*0.3
  local bvy = math.sin(angle)*spd + (owner.vy or 0)*0.3
  table.insert(ctx.bullets, {x=bx,y=by,vx=bvx,vy=bvy, life=owner.bulletLife, dmg=owner.damage, owner=owner, radius=3, weapon=bolt})
end

local function aggroChaseAndShoot(e, dt)
  local dx,dy = ctx.player.x - e.x, ctx.player.y - e.y
  local dist = util.len(dx,dy)
  local ux,uy = (dist>0 and dx/dist or 0), (dist>0 and dy/dist or 0)
  local targetSpeed = e.maxSpeed
  local desiredVx, desiredVy = ux*targetSpeed, uy*targetSpeed
  e.vx = util.lerp(e.vx, desiredVx, 0.6*dt)
  e.vy = util.lerp(e.vy, desiredVy, 0.6*dt)
  e.x = e.x + e.vx*dt
  e.y = e.y + e.vy*dt
  e.r = math.atan2(dy, dx)

  -- Only shoot after being attacked (state == "aggro")
  e.lastShot = e.lastShot + dt
  if dist < e.range and e.lastShot >= 1.0 / e.fireRate then
    fire(e)
    e.lastShot = 0
  end
end

local function regen(e, dt)
  if e.shieldCooldown>0 then e.shieldCooldown = e.shieldCooldown - dt end
  if e.shieldCooldown<=0 then e.shield = math.min(e.maxShield, e.shield + e.shieldRegen*dt) end
end

function M.onHit(e, dmg)
  e.shieldCooldown = e.shieldCDMax
  local s = math.min(e.shield, dmg)
  e.shield = e.shield - s
  dmg = dmg - s
  if dmg > 0 then e.hp = e.hp - dmg end
  -- Become aggressive *only when hit*
  e.state = "aggro"
end

function M.makeAggressive(e)
  -- Make an enemy aggressive (used when enemy successfully hits player)
  e.state = "aggro"
end

function M.generateLootContents(bonus)
  local contents = {}
  
  -- Always include some credits
  contents.credits = math.floor((bonus.cr * (0.5 + love.math.random() * 0.5)) * 100) / 100  -- 50-100% of normal credits, rounded to 2 decimal places
  
  -- Always include rockets (guaranteed)
  contents.rockets = {
    type = "rockets",
    name = "Rockets",
    quantity = math.floor(10 + love.math.random() * 20),  -- 10-30 rockets
    value = 5  -- credit value per rocket
  }
  
  -- Chance for bonus items
  if love.math.random() < 0.4 then  -- 40% chance for ammo
    contents.ammo = {
      type = "ammo",
      name = "Energy Cells",
      quantity = math.floor(5 + love.math.random() * 15),
      value = 2
    }
  end
  
  if love.math.random() < 0.2 then  -- 20% chance for repair kit
    contents.repairKit = {
      type = "repair_kit",
      name = "Nanite Repair Paste",
      quantity = 1,
      value = 50
    }
  end
  
  if love.math.random() < 0.15 then  -- 15% chance for rare item
    contents.rareItem = {
      type = "rare",
      name = "Alien Technology Fragment",
      quantity = 1,
      value = 200
    }
  end
  
  return contents
end

function M.kill(index)
  local e = ctx.enemies[index]
  if not e then return end
  ctx.camera.shake = math.max(ctx.camera.shake, 0.3)
  for k=1, 10 do
    table.insert(ctx.particles, {x=e.x, y=e.y, vx=(love.math.random()*2-1)*80, vy=(love.math.random()*2-1)*80, life=0.4+love.math.random()*0.5})
  end
  
  -- 30% chance to drop a loot box instead of regular loot
  if love.math.random() < 0.3 then
    -- Create loot box
    local lootBox = {
      x = e.x + (love.math.random()*2-1)*10,
      y = e.y + (love.math.random()*2-1)*10,
      radius = 12,
      type = "loot_box",
      life = 30,  -- Loot boxes last longer
      spin = (love.math.random()*2-1)*2,
      contents = M.generateLootContents(e.bonus)
    }
    table.insert(ctx.lootBoxes, lootBox)
  else
    -- Regular loot drop
    table.insert(ctx.loots, {x=e.x + (love.math.random()*2-1)*10, y=e.y + (love.math.random()*2-1)*10, radius=10, credits=math.floor(e.bonus.cr * 100) / 100, xp=e.bonus.xp, life=12, spin=(love.math.random()*2-1)*2})
  end
  
  table.remove(ctx.enemies, index)
end

local function spawn(dt)
  if #ctx.enemies >= ctx.G.MAX_ENEMIES then return end
  respawnTimer = respawnTimer - dt
  if respawnTimer <= 0 then
    respawnTimer = ctx.G.ENEMY_RESPAWN_TIME

    -- Try to find a valid spawn position with minimum distance from other enemies
    local maxAttempts = 10
    local validPosition = false
    local ex, ey

    for attempt = 1, maxAttempts do
      local r = 900 + love.math.random()*600  -- Distance from player
      local a = love.math.random()*math.pi*2   -- Random angle
      ex = ctx.player.x + math.cos(a)*r
      ey = ctx.player.y + math.sin(a)*r

      -- Clamp to world boundaries
      ex = util.clamp(ex, -ctx.G.WORLD_SIZE+100, ctx.G.WORLD_SIZE-100)
      ey = util.clamp(ey, -ctx.G.WORLD_SIZE+100, ctx.G.WORLD_SIZE-100)

      -- Check minimum distance from all existing enemies
      validPosition = true
      local minDistance = 200  -- Minimum 200 units between enemies

      for _, existingEnemy in ipairs(ctx.enemies) do
        local dx = ex - existingEnemy.x
        local dy = ey - existingEnemy.y
        local distance = util.len(dx, dy)
        if distance < minDistance then
          validPosition = false
          break
        end
      end

      if validPosition then break end
    end

    -- Only spawn if we found a valid position
    if validPosition then
      table.insert(ctx.enemies, M.new(ex, ey, ctx.player.level))
    end
  end
end

function M.update(dt)
  spawn(dt)
  for i = #ctx.enemies, 1, -1 do
    local e = ctx.enemies[i]
    if e.state == "idle" then
      idleWander(e, dt)
    else
      aggroChaseAndShoot(e, dt)
    end
    regen(e, dt)
    keepInWorld(e)
    if e.hp <= 0 then M.kill(i) end
  end
end

function M.draw()
  for _,e in ipairs(ctx.enemies) do
    -- Alien enemy ship with organic, menacing design
    love.graphics.setColor(0.8, 0.1, 0.2, 1) -- alien red
    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.r)

    -- Main body - irregular organic shape
    love.graphics.polygon("fill",
      8,0,    -6,6,   -4,3,   -8,0,   -4,-3,   -6,-6
    )

    -- Alien appendages/tentacles
    love.graphics.setColor(0.6, 0.05, 0.15, 1)
    love.graphics.polygon("fill", 2,4, -10,8, -6,5)
    love.graphics.polygon("fill", 2,-4, -10,-8, -6,-5)
    love.graphics.polygon("fill", -2,6, -12,10, -8,7)
    love.graphics.polygon("fill", -2,-6, -12,-10, -8,-7)

    -- Glowing alien eyes/sensors
    love.graphics.setColor(1.0, 0.3, 0.1, 1) -- orange glow
    love.graphics.circle("fill", 4, 2, 1.5)
    love.graphics.circle("fill", 4, -2, 1.5)
    love.graphics.setColor(1.0, 0.8, 0.2, 0.8) -- yellow centers
    love.graphics.circle("fill", 4, 2, 0.8)
    love.graphics.circle("fill", 4, -2, 0.8)

    love.graphics.pop()

    -- Draw shield effect if shields are active
    if e.shield > 0 then
      local shieldRadius = e.radius + 8
      local st = math.max(0, math.min(1, e.shield / e.maxShield))
      local pulse = math.sin(ctx.state.t * 8) * 0.3 + 0.7
      local alpha = 0.3 + 0.4 * st * pulse
      
      -- Outer shield ring
      love.graphics.setColor(0.8, 0.2, 0.3, alpha)  -- Reddish for enemies
      love.graphics.circle("line", e.x, e.y, shieldRadius)
      
      -- Inner shield glow
      love.graphics.setColor(1.0, 0.4, 0.5, alpha * 0.5)
      love.graphics.circle("fill", e.x, e.y, shieldRadius)
      
      -- Shield energy arcs
      for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2 + ctx.state.t * 2
        local arcX = e.x + math.cos(angle) * (shieldRadius - 2)
        local arcY = e.y + math.sin(angle) * (shieldRadius - 2)
        love.graphics.setColor(1.0, 0.6, 0.7, alpha * 0.8)
        love.graphics.circle("fill", arcX, arcY, 2)
      end
    end

    -- Shield and Health bars
    local barWidth = 24
    local barHeight = 4
    local barX = e.x - barWidth/2
    local barY = e.y - e.radius - 8
    
    -- Shield bar (above health bar)
    if e.maxShield > 0 then
      local shieldPercent = math.max(0, math.min(1, e.shield/e.maxShield))
      -- Background bar for shield
      love.graphics.setColor(0.2, 0.4, 0.8, 0.6)
      love.graphics.rectangle("fill", barX, barY - barHeight - 1, barWidth, barHeight)
      -- Shield bar (blue)
      love.graphics.setColor(0.4, 0.8, 1, 0.8)
      love.graphics.rectangle("fill", barX, barY - barHeight - 1, barWidth * shieldPercent, barHeight)
      -- Shield border
      love.graphics.setColor(0.6, 0.9, 1, 1)
      love.graphics.rectangle("line", barX, barY - barHeight - 1, barWidth, barHeight)
    end

    -- Health bar
    local healthPercent = math.max(0, math.min(1, e.hp/e.maxHP))
    -- Background bar for health
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)
    -- Health bar (green to red)
    local r = 1 - healthPercent
    local g = healthPercent
    love.graphics.setColor(r, g, 0, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)
    -- Health border
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

    -- Target ring
    if e == ctx.player.target then
      love.graphics.setColor(1,0.5,0, 0.5 + 0.3*math.sin(ctx.state.t*4))  -- pulsing orange
      love.graphics.circle("line", e.x, e.y, e.radius + 8)
      love.graphics.setColor(1,1,1,1)
    end
  end
  love.graphics.setColor(1,1,1,1)
end

return M
