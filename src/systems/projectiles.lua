local state = require("src.core.state")
local util = require("src.core.util")
local config = require("src.core.config")

local M = {}

-- Cache enemy module reference to avoid circular dependencies
local enemyModule = nil
local function getEnemyModule()
  if not enemyModule then
    enemyModule = require("src.entities.enemy")
  end
  return enemyModule
end

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
    lockOnDelay = weapon.type == "rocket" and config.projectiles.rocketLockOnDelay or 0,
    lockOnTimer = 0,
    hasLockedOn = target ~= nil  -- true if fired with initial target
  }
end

-- Create projectile from owner (ship/turret)
function M.createFromOwner(owner, weapon, target)
  local spread = (owner.spread or 0)
  local angle = owner.r + (love.math.random() * 2 - 1) * spread
  local spd = weapon.speed
  
  local px = owner.x + math.cos(angle) * (owner.radius + config.projectiles.spawnOffset)
  local py = owner.y + math.sin(angle) * (owner.radius + config.projectiles.spawnOffset)
  local pvx = math.cos(angle) * spd + (owner.vx or 0) * config.gameplay.projectileVelocityMultiplier
  local pvy = math.sin(angle) * spd + (owner.vy or 0) * config.gameplay.projectileVelocityMultiplier
  
  local projectile = newProjectile(px, py, pvx, pvy, weapon, owner, target)
  local projectiles = state.get("projectiles")
  table.insert(projectiles, projectile)
  return projectile
end

-- Shield collision detection
local function checkShieldHit(projectile, target)
  local projectileConfig = config.projectiles
  local shieldRadius = target.radius + projectileConfig.shieldRadiusOffset
  local distToCenter = util.len(projectile.x - target.x, projectile.y - target.y)
  
  if target.shield and target.shield > 0 and distToCenter <= shieldRadius then
    target.shieldCooldown = target.shieldCDMax
    
    -- Bullets do less damage to shields
    local damageMultiplier = projectile.weapon.type == "bullet" and projectileConfig.bulletShieldDamageMultiplier or 1.0
    local damageToShield = math.min(target.shield, projectile.damage * damageMultiplier)
    target.shield = target.shield - damageToShield
    target.shieldVisible = true
    return true
  end
  return false
end

-- Hit enemy
local function hitEnemy(projectile, enemyIndex)
  local enemies = state.get("enemies")
  local e = enemies[enemyIndex]
  if not e then return end
  
  -- Check shield first
  if checkShieldHit(projectile, e) then
    e.state = "aggro"
    local projectiles = state.get("projectiles")
    table.remove(projectiles, projectile._i)
    return
  end
  
  -- Direct hit - use cached enemy module to avoid circular dependency
  local enemy = getEnemyModule()
  enemy.onHit(e, projectile.damage)
  
  local projectiles = state.get("projectiles")
  table.remove(projectiles, projectile._i)
end

-- Hit player
local function hitPlayer(projectile)
  local playerEntity = state.get("player")
  local particles = state.get("particles")
  local camera = state.get("camera")
  
  -- Check shield first
  if checkShieldHit(projectile, playerEntity) then
    -- Make enemy that fired this aggressive
    if projectile.owner and projectile.owner ~= playerEntity then
      local enemy = getEnemyModule()
      enemy.makeAggressive(projectile.owner)
    end
    local projectiles = state.get("projectiles")
    table.remove(projectiles, projectile._i)
    return
  end
  
  playerEntity.hp = playerEntity.hp - projectile.damage
  
  -- Make enemy aggressive
  if projectile.owner and projectile.owner ~= playerEntity then
    local enemy = getEnemyModule()
    enemy.makeAggressive(projectile.owner)
  end
  
  local projectiles = state.get("projectiles")
  table.remove(projectiles, projectile._i)
  
  -- Handle player death
  if playerEntity.hp <= 0 then
    camera.shake = config.gameplay.cameraShakeOnDeath
    for k = 1, config.gameplay.deathParticlesCount do
      table.insert(particles, {
        x = playerEntity.x, y = playerEntity.y,
        vx = util.randf(config.gameplay.deathParticlesVx[1], config.gameplay.deathParticlesVx[2]),
        vy = util.randf(config.gameplay.deathParticlesVy[1], config.gameplay.deathParticlesVy[2]),
        life = util.randf(config.gameplay.deathParticlesLife[1], config.gameplay.deathParticlesLife[2])
      })
    end
    -- Respawn
    playerEntity.x = state.get("station").x + config.gameplay.spawnOffsetFromStation
    playerEntity.y = state.get("station").y
    playerEntity.docked = false
    playerEntity.vx, playerEntity.vy = 0, 0
    playerEntity.hp = math.max(config.gameplay.deathMinHP, math.floor(playerEntity.maxHP * config.gameplay.deathRecoveryMultiplier))
    playerEntity.shield = math.max(config.gameplay.deathMinShield, math.floor(playerEntity.maxShield * config.gameplay.deathRecoveryMultiplier))
    playerEntity.energy = playerEntity.maxEnergy
  end
end

-- Find nearest enemy target for projectile
local function findNearestEnemy(projectile, maxRange)
  local enemies = state.get("enemies")
  local projectileConfig = config.projectiles
  local nearestEnemy = nil
  local nearestDist = maxRange or projectileConfig.lockOnRange  -- 400 unit lock-on range
  
  for _, enemy in ipairs(enemies) do
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
  local projectileConfig = config.projectiles
  -- Handle lock-on delay for rockets
  if projectile.weapon.type == "rocket" and not projectile.hasLockedOn then
    projectile.lockOnTimer = projectile.lockOnTimer + dt
    
    if projectile.lockOnTimer >= projectileConfig.lockOnDelay then
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
      local homingStrength = config.projectiles.homingStrength * dt
      projectile.vx = projectile.vx + (targetVx - projectile.vx) * homingStrength
      projectile.vy = projectile.vy + (targetVy - projectile.vy) * homingStrength
    else
      -- Direct tracking for bolts and bullets
      if projectile.owner ~= state.get("player") then
        -- Enemy projectiles get perfect tracking to ensure hits
        projectile.vx = targetVx
        projectile.vy = targetVy
      else
        -- Player projectiles use normal tracking
        projectile.vx = targetVx
        projectile.vy = targetVy
      end
    end
  end
  
  return true
end

-- Main update function
function M.update(dt)
  local projectiles = state.get("projectiles")
  local i = #projectiles

  while i >= 1 do
    local p = projectiles[i]
    p._i = i

    -- Update homing if applicable
    if p.weapon.type == "rocket" or (p.target and (p.weapon.type == "bolt" or p.weapon.type == "bullet")) then
      updateHoming(p, dt)
    end

    -- Update position
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt

    -- Remove if expired
    if p.life <= 0 then
      table.remove(projectiles, i)
    else
      -- Collision detection
      if p.owner == state.get("player") then
        -- Player projectile hitting enemies
        local enemies = state.get("enemies")
        for j = #enemies, 1, -1 do
          local e = enemies[j]
          if util.len2(p.x - e.x, p.y - e.y) <= (e.radius + p.radius) * (e.radius + p.radius) then
            hitEnemy(p, j)
            break
          end
        end
      else
        -- Enemy projectile hitting player
        local playerEntity = state.get("player")
        if util.len2(p.x - playerEntity.x, p.y - playerEntity.y) <= (playerEntity.radius + p.radius) * (playerEntity.radius + p.radius) then
          hitPlayer(p)
        end
      end
    end

    i = i - 1
  end
end

-- Render all projectiles
function M.draw()
  local projectiles = state.get("projectiles")
  for _, p in ipairs(projectiles) do
    local rot = math.atan2(p.vy, p.vx)
    p.weapon.draw(p.x, p.y, rot)
  end
end

-- Initialize projectiles array in context
function M.init()
  state.set("projectiles", {})
end

return M
