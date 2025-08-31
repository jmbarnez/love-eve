local ctx = require("src.core.ctx")
local util = require("src.core.util")
local projectiles = require("src.entities.projectile")
local bolt = require("src.content.weapons.bolt")

local M = {}
local respawnTimer = 0

local function preset(level)
  local tier = math.min(1+math.floor((level-1)/3), 4)
  local presets = {
    [1] = {hp=40, shield=30, speed=300, damage=10, fireRate=0.9, range=520, bonus= {xp=20, cr=30, tier=1}},
    [2] = {hp=70, shield=60, speed=350, damage=12, fireRate=1.2, range=640, bonus= {xp=30, cr=45, tier=2}},
    [3] = {hp=110, shield=90, speed=400, damage=16, fireRate=1.6, range=700, bonus= {xp=40, cr=65, tier=3}},
    [4] = {hp=160, shield=140, speed=450, damage=20, fireRate=2.0, range=760, bonus= {xp=55, cr=90, tier=4}},
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
    damage=p.damage, fireRate=p.fireRate,
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

-- Fire projectile at player
local function fire(owner)
  projectiles.createFromOwner(owner, bolt, ctx.player)
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
  local items = require("src.content.items")
  local tier = bonus.tier or 1  -- Enemy tier for scaling drops
  return items.generateRandomLoot(tier, bonus.cr)
end

function M.kill(index)
  local e = ctx.enemies[index]
  if not e then return end
  ctx.camera.shake = math.max(ctx.camera.shake, 0.3)
  for k=1, 10 do
    table.insert(ctx.particles, {x=e.x, y=e.y, vx=(love.math.random()*2-1)*80, vy=(love.math.random()*2-1)*80, life=0.4+love.math.random()*0.5})
  end
  
  -- Always drop a loot box (container)
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

    -- Draw shield effect only when actively blocking damage
    if e.shield > 0 and e.shieldCooldown > 0 then
      local shieldRadius = e.radius + 8
      
      -- Simple blue circle shield
      love.graphics.setColor(0.2, 0.4, 1.0, 0.6)
      love.graphics.circle("line", e.x, e.y, shieldRadius)
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

  end
  love.graphics.setColor(1,1,1,1)
end

return M
