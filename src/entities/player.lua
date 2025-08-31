
local ctx    = require("src.core.state")
local util   = require("src.core.util")
local ship   = require("src.content.ships.starter")

local M = {}

function M.new()
  return {
    x=0,y=0, vx=0,vy=0, r=0,
    radius=14,
<<<<<<< HEAD
    accel=120,
    maxSpeed=1000,
    friction=1.0,
    afterburner=240,
    energy=100, maxEnergy=100, energyRegen=14,
    hp=100, maxHP=100,
    shield=120, maxShield=120, shieldRegen=10, shieldCooldown=0, shieldCDMax=2.0,
    damage=16,
    fireRate=8, -- shots/sec
=======
    accel=80,
    maxSpeed=200,
    friction=1.0,
    energy=100, maxEnergy=100, energyRegen=14,
    hp=100, maxHP=100,
    shield=120, maxShield=120, shieldRegen=10, shieldCooldown=0, shieldCDMax=2.0,
    damage=12,
    fireCooldown=0, -- seconds until next shot allowed
    fireCooldownMax=2.0, -- fixed cooldown for default attack
>>>>>>> a91d4cc (Fixed combat and movement)
    spread=0.06,
    lastShot=0,
    credits=0.00,
    inventory={}, -- Player inventory
    level=1,
    xp=0,
    xpToNext=100,
    docked=false,
    moveTarget=nil,
<<<<<<< HEAD
    lastRocketShot=0,
=======
    attackTarget=nil, -- Auto attack target
    moveMarker={x=0, y=0, timer=0}, -- Temporary visual marker for right-click movement
>>>>>>> a91d4cc (Fixed combat and movement)
  }
end

function M.init()
  ctx.station = {x=0,y=0}
  ctx.player = M.new()
  -- Start near station but not docked
  ctx.player.x = ctx.station.x + 150  -- offset to the right
  ctx.player.y = ctx.station.y
  ctx.player.docked = false
  ctx.player.r = math.pi  -- face left towards station
  
  -- Initialize inventory with starting items
<<<<<<< HEAD
  M.addToInventory("rockets", 500)
=======
>>>>>>> a91d4cc (Fixed combat and movement)
  M.addToInventory("energy_cells", 200)
  M.addToInventory("repair_kit", 5)
  M.addToInventory("shield_booster", 2)
  M.addToInventory("alien_tech", 1)
end

local function applyMovement(dt)
  local p = ctx.player
<<<<<<< HEAD
  
=======

>>>>>>> a91d4cc (Fixed combat and movement)
  -- Handle right-click movement
  if p.moveTarget then
    local dx = p.moveTarget.x - p.x
    local dy = p.moveTarget.y - p.y
    local dist = util.len(dx, dy)
<<<<<<< HEAD
    
=======

>>>>>>> a91d4cc (Fixed combat and movement)
    if dist < 15 then
      -- Reached destination
      p.moveTarget = nil
      p.vx = p.vx * 0.8  -- Slow down when reaching target
      p.vy = p.vy * 0.8
    else
      -- Move toward target
      local ux, uy = dx / dist, dy / dist
      local desiredSpeed = math.min(p.maxSpeed, dist * 2)  -- Slow down as we approach
      local dvx, dvy = ux * desiredSpeed - p.vx, uy * desiredSpeed - p.vy
<<<<<<< HEAD
      
      p.vx = p.vx + dvx * 5.0 * dt  -- Responsive movement
      p.vy = p.vy + dvy * 5.0 * dt
      
      -- Only face movement direction when not recently firing
      if p.lastRocketShot > 0.5 then  -- 0.5 second grace period after firing
        p.r = math.atan2(dy, dx)
      end
      
      -- Energy consumption
      p.energy = math.max(0, p.energy - 15 * dt)
=======

      p.vx = p.vx + dvx * 5.0 * dt  -- Responsive movement
      p.vy = p.vy + dvy * 5.0 * dt

      -- Only face movement direction when not recently firing
      if p.lastShot > 0.5 then  -- 0.5 second grace period after firing
        p.r = math.atan2(dy, dx)
      end

      -- Energy consumption for movement (reduced from 12 to 6 per second)
      p.energy = math.max(0, p.energy - 6 * dt)
>>>>>>> a91d4cc (Fixed combat and movement)
    end
  else
    -- No target, regenerate energy faster
    p.energy = math.min(p.maxEnergy, p.energy + p.energyRegen * dt)
  end
<<<<<<< HEAD
end

-- Function to set move target from right-click
function M.setMoveTarget(x, y)
  if not ctx.player.docked then
    ctx.player.moveTarget = {x = x, y = y}
=======
end-- Function to set move target from right-click
function M.setMoveTarget(x, y)
  if not ctx.player.docked then
    ctx.player.moveTarget = {x = x, y = y}
    -- Set temporary visual marker (like League of Legends right-click effect)
    ctx.player.moveMarker = {x = x, y = y, timer = 1.25} -- 1.25 second duration (twice as fast)
  end
end

-- Function to set attack target
function M.setAttackTarget(enemy)
  if not ctx.player.docked then
    ctx.player.attackTarget = enemy
>>>>>>> a91d4cc (Fixed combat and movement)
  end
end

local function clampPhysics(dt)
  local p = ctx.player
  local spd = util.len(p.vx, p.vy)
  if spd > p.maxSpeed then local s = p.maxSpeed/spd; p.vx = p.vx*s; p.vy = p.vy*s end

  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt

  -- keep in world
  local W = ctx.G.WORLD_SIZE
  if p.x < -W then p.x = -W; p.vx = math.abs(p.vx) end
  if p.x > W then p.x = W; p.vx = -math.abs(p.vx) end
  if p.y < -W then p.y = -W; p.vy = math.abs(p.vy) end
  if p.y > W then p.y = W; p.vy = -math.abs(p.vy) end

  -- face mouse
  local mx,my = love.mouse.getPosition()
  local lg = love.graphics
  local wx = ctx.camera.x + (mx - lg.getWidth()/2)/ctx.G.ZOOM
  local wy = ctx.camera.y + (my - lg.getHeight()/2)/ctx.G.ZOOM
  ctx.player.r = math.atan2(wy - p.y, wx - p.x)
end

local function regen(dt)
  local p = ctx.player
  if p.shieldCooldown>0 then p.shieldCooldown = p.shieldCooldown - dt end
  if p.shieldCooldown<=0 then
    p.shield = math.min(p.maxShield, p.shield + p.shieldRegen*dt)
  end
end

local function shooting(dt)
  local p = ctx.player
<<<<<<< HEAD
  p.lastRocketShot = p.lastRocketShot + dt
end

-- Function to fire rocket toward mouse position
function M.fireRocket(mouseX, mouseY)
  local p = ctx.player
  if p.docked or not M.hasItem("rockets", 1) then return false end
  
  local rocketInterval = 1.0 / 2.0  -- Faster fire rate for active combat
  if p.lastRocketShot < rocketInterval then return false end
  
  -- Calculate world position of mouse
  local lg = love.graphics
  local wx = ctx.camera.x + (mouseX - lg.getWidth()/2)/ctx.G.ZOOM
  local wy = ctx.camera.y + (mouseY - lg.getHeight()/2)/ctx.G.ZOOM
  
  -- Face toward mouse for firing
  local dx, dy = wx - p.x, wy - p.y
  p.r = math.atan2(dy, dx)
  
  local projectiles = require("src.systems.projectiles")
  local rocketLauncher = require("src.models.projectiles.types.rocket_launcher")
  
  -- Fire rocket toward mouse cursor (no initial target - will lock on later)
  projectiles.createFromOwner(p, rocketLauncher, nil)
  
  M.removeFromInventory("rockets", 1)
  p.lastRocketShot = 0
  ctx.camera.shake = math.min(0.1, ctx.camera.shake + 0.05)
  return true
=======
  p.lastShot = math.min(p.lastShot + dt, 1.0)  -- Cap at 1 second to prevent overflow
  -- decrease explicit cooldown timer
  p.fireCooldown = math.max(0, (p.fireCooldown or 0) - dt)

  -- Auto attack if we have a target and it's alive
  if p.attackTarget and p.attackTarget.hp > 0 then
    local dx = p.attackTarget.x - p.x
    local dy = p.attackTarget.y - p.y
    local dist = util.len(dx, dy)

    -- Only shoot if within reasonable range and have enough energy
    if dist < 600 and p.fireCooldown <= 0 and p.energy >= 4 then
      -- Face the target
      p.r = math.atan2(dy, dx)

      -- Fire bullet at target
      local projectiles = require("src.systems.projectiles")
      local bullet = require("src.models.projectiles.types.bullet")
      projectiles.createFromOwner(p, bullet, p.attackTarget)

      -- Consume energy for shooting (reduced from 8 to 4 per shot)
      p.energy = math.max(0, p.energy - 4)

      -- reset timers
      p.lastShot = 0
      p.fireCooldown = p.fireCooldownMax
      ctx.camera.shake = math.min(0.05, ctx.camera.shake + 0.01)
    end
  else
    -- Clear dead target
    p.attackTarget = nil
  end
end-- Function to fire rocket toward mouse position
function M.fireRocket(mouseX, mouseY)
  -- Rockets removed - now using auto attack with bullets
  return false
>>>>>>> a91d4cc (Fixed combat and movement)
end

function M.update(dt)
  applyMovement(dt)
  clampPhysics(dt)
  regen(dt)
  shooting(dt)
<<<<<<< HEAD
=======
  
  -- Update move marker timer
  if ctx.player.moveMarker.timer > 0 then
    ctx.player.moveMarker.timer = ctx.player.moveMarker.timer - dt
  end
>>>>>>> a91d4cc (Fixed combat and movement)
end

function M.addToInventory(itemType, quantity)
  if not ctx.player.inventory[itemType] then
    ctx.player.inventory[itemType] = 0
  end
  ctx.player.inventory[itemType] = ctx.player.inventory[itemType] + quantity
end

function M.removeFromInventory(itemType, quantity)
  if ctx.player.inventory[itemType] and ctx.player.inventory[itemType] >= quantity then
    ctx.player.inventory[itemType] = ctx.player.inventory[itemType] - quantity
    return true
  end
  return false
end

function M.getInventoryCount(itemType)
  return ctx.player.inventory[itemType] or 0
end

function M.hasItem(itemType, quantity)
  return (ctx.player.inventory[itemType] or 0) >= quantity
end

function M.getEnemyUnderMouse()
  local mx, my = love.mouse.getPosition()

  -- Convert screen coordinates to world coordinates
  local wx = ctx.camera.x + (mx - love.graphics.getWidth()/2) / ctx.G.ZOOM
  local wy = ctx.camera.y + (my - love.graphics.getHeight()/2) / ctx.G.ZOOM

  -- Check each enemy to see if mouse is over it
  for _, enemy in ipairs(ctx.enemies) do
    local dx = wx - enemy.x
    local dy = wy - enemy.y
    local distance = util.len(dx, dy)

    -- Use a slightly larger radius for mouse interaction (same as the green circle)
    if distance <= enemy.radius + 12 then
      return enemy
    end
  end

  return nil
end

local function drawShield()
  local p = ctx.player
  
  -- Only show shield when it's actively blocking damage (shieldCooldown > 0)
  if p.shield > 0 and p.shieldCooldown > 0 then
    local shieldRadius = p.radius + 8
    
    -- Simple blue circle shield
    love.graphics.setColor(0.2, 0.4, 1.0, 0.6)
    love.graphics.circle("line", p.x, p.y, shieldRadius)
  end
  
  love.graphics.setColor(1,1,1,1)
end

function M.draw()
  ship.draw(ctx.player.x, ctx.player.y, ctx.player.r, 1.0, util.len(ctx.player.vx, ctx.player.vy)/ctx.player.maxSpeed)
  drawShield()
<<<<<<< HEAD
=======
  
  -- Draw attack target indicator
  if ctx.player.attackTarget and ctx.player.attackTarget.hp > 0 then
    love.graphics.setColor(1.0, 0.5, 0.0, 0.8) -- Orange indicator
    love.graphics.circle("line", ctx.player.attackTarget.x, ctx.player.attackTarget.y, ctx.player.attackTarget.radius + 6)
    love.graphics.setColor(1,1,1,1)
  end
  
  -- Draw temporary move marker (League of Legends style)
  if ctx.player.moveMarker.timer > 0 then
    local marker = ctx.player.moveMarker
    local alpha = marker.timer / 1.25 -- Fade from 1.0 to 0.0 over 1.25 seconds
    local radius = 20 + (1 - alpha) * 10 -- Expand slightly as it fades
    
    -- Outer ring
    love.graphics.setColor(0.8, 0.9, 1.0, alpha * 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", marker.x, marker.y, radius)
    
    -- Inner ring
    love.graphics.setColor(0.6, 0.8, 1.0, alpha * 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", marker.x, marker.y, radius * 0.7)
    
    -- Center dot
    love.graphics.setColor(0.8, 0.9, 1.0, alpha)
    love.graphics.circle("fill", marker.x, marker.y, 3)
    
    love.graphics.setColor(1, 1, 1, 1)
  end
>>>>>>> a91d4cc (Fixed combat and movement)
end

function M.regenDocked(dt)
  local p = ctx.player
  -- Faster regen when docked
  p.hp = math.min(p.maxHP, p.hp + 20*dt)
  p.shield = math.min(p.maxShield, p.shield + 30*dt)
  p.energy = math.min(p.maxEnergy, p.energy + 40*dt)
end

return M
