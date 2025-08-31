
local ctx    = require("src.core.ctx")
local util   = require("src.core.util")
local bullets= require("src.entities.bullet")
local ship   = require("src.content.ships.starter")

local M = {}

function M.new()
  return {
    x=0,y=0, vx=0,vy=0, r=0,
    radius=14,
    accel=120,
    maxSpeed=1000,
    friction=1.0,
    afterburner=240,
    energy=100, maxEnergy=100, energyRegen=14,
    hp=100, maxHP=100,
    shield=120, maxShield=120, shieldRegen=10, shieldCooldown=0, shieldCDMax=2.0,
    damage=16,
    fireRate=8, -- shots/sec
    bulletSpeed=560,
    bulletLife=1.2,
    spread=0.06,
    lastShot=0,
    credits=0.00,
    inventory={}, -- Player inventory
    level=1,
    xp=0,
    xpToNext=100,
    docked=false,
    autopilot=nil,
    target=nil,
    lastRocketShot=0,
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
  M.addToInventory("rockets", 500)
end

local function applyMovement(dt)
  local p = ctx.player
  local ax,ay = 0,0
  if love.keyboard.isDown("w") then ay = ay - 1 end
  if love.keyboard.isDown("s") then ay = ay + 1 end
  if love.keyboard.isDown("a") then ax = ax - 1 end
  if love.keyboard.isDown("d") then ax = ax + 1 end
  local nx,ny = util.norm(ax,ay)
  local thrusting = nx ~= 0 or ny ~= 0

  local maxA = p.accel
  if love.keyboard.isDown("lshift","rshift") and p.energy>0 then
    maxA = p.afterburner
    p.energy = math.max(0, p.energy - 40*dt)
  elseif thrusting then
    p.energy = math.max(0, p.energy - 10*dt)
  else
    p.energy = math.min(p.maxEnergy, p.energy + p.energyRegen*dt)
  end
  if thrusting or love.keyboard.isDown("lshift","rshift") then
    p.vx = p.vx + nx * maxA * dt
    p.vy = p.vy + ny * maxA * dt
  end
end

local function applyAutopilot(dt)
  local p = ctx.player
  if ctx.state.autopilotFollowMouse and not p.docked then
    local mx,my = love.mouse.getPosition()
    local lg = love.graphics
    local wx = ctx.camera.x + (mx - lg.getWidth()/2)/ctx.G.ZOOM
    local wy = ctx.camera.y + (my - lg.getHeight()/2)/ctx.G.ZOOM
    local dx,dy = wx - p.x, wy - p.y
    local ux,uy = util.norm(dx,dy)
    p.vx = p.vx + ux * p.accel * dt
    p.vy = p.vy + uy * p.accel * dt
  end
  if p.autopilot and not p.docked then
    local dx = p.autopilot.tx - p.x
    local dy = p.autopilot.ty - p.y
    local dist = util.len(dx,dy)
    if dist < 10 then
      p.autopilot = nil
    else
      local ux,uy = dx/dist, dy/dist
      local desired = math.min(p.maxSpeed, 80 + dist*0.8)
      local dvx, dvy = ux*desired - p.vx, uy*desired - p.vy
      p.vx = p.vx + dvx * 0.8 * dt
      p.vy = p.vy + dvy * 0.8 * dt
    end
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
  p.lastShot = p.lastShot + dt
  local fireInterval = 1.0 / p.fireRate

  -- Auto attack target with rocket (existing functionality)
  if p.target and p.target.hp > 0 and not p.docked and M.hasItem("rockets", 1) then
    local tx, ty = p.target.x, p.target.y
    local dx, dy = tx - p.x, ty - p.y
    local dist = util.len(dx, dy)
    local maxRange = 800  -- Player weapon range

    if dist <= maxRange and dist > 0 then
      p.lastRocketShot = p.lastRocketShot + dt
      local rocketInterval = 2.0  -- fire every 2 seconds
      if p.lastRocketShot >= rocketInterval then
        -- Fire rocket towards target
        local angle = math.atan2(dy, dx)
        local spd = 800  -- faster rocket
        local bx = p.x + math.cos(angle) * (p.radius + 8)
        local by = p.y + math.sin(angle) * (p.radius + 8)
        local bvx = math.cos(angle) * spd
        local bvy = math.sin(angle) * spd
        table.insert(ctx.bullets, {x=bx, y=by, vx=bvx, vy=bvy, life=5.0, dmg=p.damage, owner=p, radius=3, weapon=require("src.content.weapons.rocket"), target=p.target})
        M.removeFromInventory("rockets", 1)  -- Consume a rocket from inventory
        p.lastRocketShot = 0
        ctx.camera.shake = math.min(0.1, ctx.camera.shake + 0.05)
      end
    end
  else
    p.target = nil
  end
end

function M.update(dt)
  applyMovement(dt)
  applyAutopilot(dt)
  clampPhysics(dt)
  regen(dt)
  shooting(dt)
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

local function drawShield()
  local p = ctx.player
  local st = math.max(0, math.min(1, p.shield / p.maxShield))
  
  if p.shield > 0 then
    -- Draw shield bubble effect
    local shieldRadius = p.radius + 8
    local pulse = math.sin(ctx.state.t * 8) * 0.3 + 0.7
    local alpha = 0.3 + 0.4 * st * pulse
    
    -- Outer shield ring
    love.graphics.setColor(0.4, 0.8, 1, alpha)
    love.graphics.circle("line", p.x, p.y, shieldRadius)
    
    -- Inner shield glow
    love.graphics.setColor(0.6, 0.9, 1, alpha * 0.5)
    love.graphics.circle("fill", p.x, p.y, shieldRadius)
    
    -- Shield energy arcs
    for i = 1, 6 do
      local angle = (i / 6) * math.pi * 2 + ctx.state.t * 2
      local arcX = p.x + math.cos(angle) * (shieldRadius - 2)
      local arcY = p.y + math.sin(angle) * (shieldRadius - 2)
      love.graphics.setColor(0.8, 1, 1, alpha * 0.8)
      love.graphics.circle("fill", arcX, arcY, 2)
    end
  end
  
  love.graphics.setColor(1,1,1,1)
end

function M.draw()
  ship.draw(ctx.player.x, ctx.player.y, ctx.player.r, 1.0, util.len(ctx.player.vx, ctx.player.vy)/ctx.player.maxSpeed)
  drawShield()
end

return M
