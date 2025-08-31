-- Universal Projectile System
-- Handles all projectile types: bullets, rockets, missiles, etc.

local ctx   = require("src.core.state")
local util  = require("src.core.util")

local M = {}

-- Projectile types
local TYPES = {
  BOLT = "bolt",
  ROCKET = "rocket",
  MISSILE = "missile",
  PLASMA = "plasma"
}
M.TYPES = TYPES

-- Create new projectile
local function newProjectile(x, y, vx, vy, weapon, owner, target)
  return {
    x = x, y = y,
    vx = vx, vy = vy,
    life = weapon.lifetime,
    damage = weapon.damage,
    owner = owner,
    weapon = weapon,
    target = target,
    radius = weapon.radius or 3,
    type = weapon.type,
    lockOnDelay = weapon.type == "rocket" and 0.3 or 0,  -- 0.3 second lock-on delay for rockets
    lockOnTimer = 0,
    hasLockedOn = target ~= nil  -- true if fired with initial target
  }
end

-- Create projectile from owner (ship/turret)
function M.createFromOwner(owner, weapon, target)
  local spread = (owner.spread or 0)
  local angle = owner.r + (love.math.random() * 2 - 1) * spread
  local spd = weapon.speed
  
  local px = owner.x + math.cos(angle) * (owner.radius + 8)
  local py = owner.y + math.sin(angle) * (owner.radius + 8)
  local pvx = math.cos(angle) * spd + (owner.vx or 0) * 0.3
  local pvy = math.sin(angle) * spd + (owner.vy or 0) * 0.3
  
  local projectile = newProjectile(px, py, pvx, pvy, weapon, owner, target)
  table.insert(ctx.projectiles, projectile)
  return projectile
end

-- Shield collision detection
local function checkShieldHit(projectile, target)
  local shieldRadius = target.radius + 8
  local distToCenter = util.len(projectile.x - target.x, projectile.y - target.y)
  
  if target.shield > 0 and distToCenter <= shieldRadius then
    target.shieldCooldown = target.shieldCDMax
<<<<<<< HEAD
    local damageToShield = math.min(target.shield, projectile.damage)
=======
    
    -- Bullets do less damage to shields
    local damageMultiplier = projectile.weapon.type == "bullet" and 0.5 or 1.0
    local damageToShield = math.min(target.shield, projectile.damage * damageMultiplier)
>>>>>>> a91d4cc (Fixed combat and movement)
    target.shield = target.shield - damageToShield
    target.shieldVisible = true
    return true
  end
  return false
end

-- Hit enemy
local function hitEnemy(projectile, enemyIndex)
  local e = ctx.enemies[enemyIndex]
  if not e then return end
  
  -- Check shield first
  if checkShieldHit(projectile, e) then
    e.state = "aggro"
    table.remove(ctx.projectiles, projectile._i)
    return
  end
  
  -- Direct hit - use enemy module loaded dynamically to avoid circular dependency
  local enemy = require("src.entities.enemy")
  enemy.onHit(e, projectile.damage)
  
    table.remove(ctx.projectiles, projectile._i)
end

-- Hit player
local function hitPlayer(projectile)
  local p = ctx.player
  
  -- Check shield first
  if checkShieldHit(projectile, p) then
    -- Make enemy that fired this aggressive
    if projectile.owner and projectile.owner ~= ctx.player then
      local enemy = require("src.entities.enemy")
      enemy.makeAggressive(projectile.owner)
    end
    table.remove(ctx.projectiles, projectile._i)
    return
  end
  
  p.hp = p.hp - projectile.damage
  
  -- Make enemy aggressive
  if projectile.owner and projectile.owner ~= ctx.player then
    local enemy = require("src.entities.enemy")
    enemy.makeAggressive(projectile.owner)
  end
  
    table.remove(ctx.projectiles, projectile._i)
  
  -- Handle player death
  if p.hp <= 0 then
    ctx.camera.shake = 1.0
    for k = 1, 40 do
      table.insert(ctx.particles, {
        x = p.x, y = p.y,
        vx = util.randf(-120, 120),
        vy = util.randf(-120, 120),
        life = util.randf(0.6, 1.2)
      })
    end
    -- Respawn
    p.x = ctx.station.x + 150
    p.y = ctx.station.y
    p.docked = false
    p.vx, p.vy = 0, 0
    p.hp = math.max(30, math.floor(p.maxHP * 0.6))
    p.shield = math.max(40, math.floor(p.maxShield * 0.6))
    p.energy = p.maxEnergy
  end
end

-- Find nearest enemy target for projectile
local function findNearestEnemy(projectile, maxRange)
  local nearestEnemy = nil
  local nearestDist = maxRange or 400  -- 400 unit lock-on range
  
  for _, enemy in ipairs(ctx.enemies) do
    if enemy.hp > 0 then
      local dx = enemy.x - projectile.x
      local dy = enemy.y - projectile.y
      local dist = util.len(dx, dy)
      
      if dist < nearestDist then
        nearestDist = dist
        nearestEnemy = enemy
      end
    end
  end
  
  return nearestEnemy
end

-- Update homing behavior
local function updateHoming(projectile, dt)
  -- Handle lock-on delay for rockets
  if projectile.weapon.type == "rocket" and not projectile.hasLockedOn then
    projectile.lockOnTimer = projectile.lockOnTimer + dt
    
    if projectile.lockOnTimer >= projectile.lockOnDelay then
      -- Time to lock onto nearest enemy
      projectile.target = findNearestEnemy(projectile)
      projectile.hasLockedOn = true
    else
      -- Still in lock-on delay, fly straight
      return true
    end
  end
  
  if not projectile.target or projectile.target.hp <= 0 then
    -- Try to find new target for rockets
    if projectile.weapon.type == "rocket" and projectile.hasLockedOn then
      projectile.target = findNearestEnemy(projectile)
    end
    
    if not projectile.target then
      return true  -- Keep flying straight if no target
    end
  end
  
  local dx = projectile.target.x - projectile.x
  local dy = projectile.target.y - projectile.y
  local dist = util.len(dx, dy)
  
  if dist > 0 then
    local spd = projectile.weapon.speed
    local targetVx = (dx / dist) * spd
    local targetVy = (dy / dist) * spd
    
    -- Smooth homing for rockets
    if projectile.weapon.type == "rocket" then
      local homingStrength = 5.0 * dt
      projectile.vx = projectile.vx + (targetVx - projectile.vx) * homingStrength
      projectile.vy = projectile.vy + (targetVy - projectile.vy) * homingStrength
    else
<<<<<<< HEAD
      -- Direct tracking for bolts - more aggressive for enemy projectiles
      if projectile.owner ~= ctx.player then
        -- Enemy bolts get perfect tracking to ensure hits
        projectile.vx = targetVx
        projectile.vy = targetVy
      else
        -- Player bolts use normal tracking
=======
      -- Direct tracking for bolts and bullets
      if projectile.owner ~= ctx.player then
        -- Enemy projectiles get perfect tracking to ensure hits
        projectile.vx = targetVx
        projectile.vy = targetVy
      else
        -- Player projectiles use normal tracking
>>>>>>> a91d4cc (Fixed combat and movement)
        projectile.vx = targetVx
        projectile.vy = targetVy
      end
    end
  end
  
  return true
end

-- Main update function
function M.update(dt)
  for i = #ctx.projectiles, 1, -1 do
    local p = ctx.projectiles[i]
    p._i = i
    
    -- Update homing if applicable
<<<<<<< HEAD
    if p.weapon.type == "rocket" or (p.target and p.weapon.type == "bolt") then
=======
    if p.weapon.type == "rocket" or (p.target and (p.weapon.type == "bolt" or p.weapon.type == "bullet")) then
>>>>>>> a91d4cc (Fixed combat and movement)
      updateHoming(p, dt)
    end
    
    -- Update position
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    
    -- Remove if expired
    if p.life <= 0 then
      table.remove(ctx.projectiles, i)
      goto continue
    end
    
    -- Collision detection
    if p.owner == ctx.player then
      -- Player projectile hitting enemies
      for j = #ctx.enemies, 1, -1 do
        local e = ctx.enemies[j]
        if util.len2(p.x - e.x, p.y - e.y) <= (e.radius + p.radius) * (e.radius + p.radius) then
          hitEnemy(p, j)
          break
        end
      end
    else
      -- Enemy projectile hitting player
      local player = ctx.player
      if util.len2(p.x - player.x, p.y - player.y) <= (player.radius + p.radius) * (player.radius + p.radius) then
        hitPlayer(p)
      end
    end
    
    ::continue::
  end
end

-- Render all projectiles
function M.draw()
  for _, p in ipairs(ctx.projectiles) do
    local rot = math.atan2(p.vy, p.vx)
    p.weapon.draw(p.x, p.y, rot)
  end
end

-- Initialize projectiles array in context
function M.init()
  ctx.projectiles = ctx.projectiles or {}
end

return M