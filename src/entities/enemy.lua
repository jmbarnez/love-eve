local state = require("src.core.state")
local util = require("src.core.util")
local projectiles = require("src.systems.projectiles")
local config = require("src.core.config")

local M = {}

-- Enemy variants for more variety (loaded from config)
local enemyVariants = {
  drone = {
    name = "drone",
    color = {0.8, 0.1, 0.2},
    baseSpeed = 1.0,
    fireRateBonus = 1.0,
    hpBonus = 1.0,
    damageBonus = 1.0,
    rangeBonus = 1.0,
    rewardBonus = 1.0
  }
}

local function preset(level)
  local enemyConfig = config.enemy
  local tier = math.min(1+math.floor((level-1)/3), 4)
  return enemyConfig.presets[tier]
end

function M.new(px,py, level)
  local enemyConfig = config.enemy
  local p = preset(level)
  local variant = enemyVariants.drone

  -- Base stats with procedural variation (±15%)
  local hpVariation = 1 + (love.math.random() - 0.5) * 0.3
  local speedVariation = 1 + (love.math.random() - 0.5) * 0.3
  local damageVariation = 1 + (love.math.random() - 0.5) * 0.3
  local fireRateVariation = 1 + (love.math.random() - 0.5) * 0.3

  local baseHP = p.hp * variant.hpBonus
  local baseSpeed = p.speed * variant.baseSpeed
  local baseDamage = p.damage * variant.damageBonus
  local baseFireRate = p.fireCooldownMax * variant.fireRateBonus
  local baseRange = p.range * variant.rangeBonus

  return {
    x=px, y=py, vx=0, vy=0, r=0, radius=enemyConfig.radius,
    hp=baseHP * hpVariation, maxHP=baseHP * hpVariation,
    accel=200, maxSpeed=baseSpeed * speedVariation, friction=1.0,
    damage=baseDamage * damageVariation, fireCooldown=0, fireCooldownMax=baseFireRate * fireRateVariation,
    spread=0.01, lastShot=0, range=baseRange,
    bonus={tier=math.max(1, math.min(4, p.tier)), cr=p.creditReward * variant.rewardBonus, variant=variant},
    state="idle", -- becomes "aggro" only when attacked
    color=variant.color,
    variant=variant.name,
    spawnX = px, spawnY = py, -- Store spawn point
    roamTargetX = px + (love.math.random() * 2 - 1) * 150, -- Initial roam target
    roamTargetY = py + (love.math.random() * 2 - 1) * 150,
    roamTimer = 0 -- Timer to change roam target
  }
end

function M.init()
  state.set("enemies", {})
end

local function keepInWorld(e)
  local gameConfig = state.get("config").game
  local W = gameConfig.WORLD_SIZE
  if e.x < -W then e.x = -W; e.vx = math.abs(e.vx) end
  if e.x > W then e.x = W; e.vx = -math.abs(e.vx) end
  if e.y < -W then e.y = -W; e.vy = math.abs(e.vy) end
  if e.y > W then e.y = W; e.vy = -math.abs(e.vy) end
end

local function idleWander(e, dt)
  -- Roaming behavior around spawn point
  e.roamTimer = e.roamTimer + dt

  -- Every 3-6 seconds, pick a new roam target near spawn point
  if e.roamTimer > 3 + love.math.random() * 3 then
    e.roamTimer = 0
    local angle = love.math.random() * 2 * math.pi
    local distance = 50 + love.math.random() * 100  -- Roam within 50-150 pixels of spawn
    e.roamTargetX = e.spawnX + math.cos(angle) * distance
    e.roamTargetY = e.spawnY + math.sin(angle) * distance
  end

  -- Steer toward roam target
  local dx = e.roamTargetX - e.x
  local dy = e.roamTargetY - e.y
  local distToTarget = math.sqrt(dx*dx + dy*dy)
  if distToTarget > 10 then  -- If not at target, accelerate toward it
    local speedFactor = math.min(1, distToTarget / 20)  -- Slow down when close
    local desiredVx = (dx / distToTarget) * e.maxSpeed * 0.5 * speedFactor  -- Half speed for roaming
    local desiredVy = (dy / distToTarget) * e.maxSpeed * 0.5 * speedFactor

    e.vx = util.lerp(e.vx, desiredVx, 0.2 * dt)  -- Smooth acceleration
    e.vy = util.lerp(e.vy, desiredVy, 0.2 * dt)
  else
    -- Slowly drift when at target
    e.vx = e.vx * 0.9
    e.vy = e.vy * 0.9
  end

  -- Apply movement and friction
  e.x = e.x + e.vx * dt
  e.y = e.y + e.vy * dt

  -- Update rotation based on movement direction
  if e.vx ~= 0 or e.vy ~= 0 then
    e.r = math.atan2(e.vy, e.vx)
  end
end

-- Fire projectile at player
local function fire(owner)
  local bullet = require("src.content.projectiles.types.bullet")
  projectiles.createFromOwner(owner, bullet, state.get("player"))
end

local function aggroChaseAndShoot(e, dt)
  local playerEntity = state.get("player")
  local dx,dy = playerEntity.x - e.x, playerEntity.y - e.y
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
  e.lastShot = math.min(e.lastShot + dt, 1.0)  -- Cap at 1 second to prevent overflow
  e.fireCooldown = math.max(0, e.fireCooldown - dt)
  if dist < e.range and e.fireCooldown <= 0 then
    fire(e)
    e.lastShot = 0
    e.fireCooldown = e.fireCooldownMax
  end
end

function M.onHit(e, dmg)
  -- No shields, direct damage to HP
  e.hp = e.hp - dmg
  -- Become aggressive *only when hit*
  e.state = "aggro"
end

function M.makeAggressive(e)
  -- Make an enemy aggressive (used when enemy successfully hits player)
  e.state = "aggro"
end

function M.generateLootContents(bonus)
  bonus = bonus or {}
  local items = require("src.content.items.registry")
  local tier = bonus.tier or 1  -- Enemy tier for scaling drops
  return items.generateRandomLoot(tier, bonus.cr)
end

function M.kill(index)
  local enemies = state.get("enemies")
  local particles = state.get("particles")
  local camera = state.get("camera")
  local e = enemies[index]
  if not e then return end
  camera.shake = math.max(camera.shake, 0.3)
  for k=1, 10 do
    table.insert(particles, {x=e.x, y=e.y, vx=(love.math.random()*2-1)*80, vy=(love.math.random()*2-1)*80, life=0.4+love.math.random()*0.5})
  end
  
  -- Create wreckage with loot contents
  local contents = M.generateLootContents(e.bonus)
  if next(contents) ~= nil then
    local wreckage = require("src.entities.wreckage")
    wreckage.create(e.x, e.y, e.variant, e.r, contents)
  end
  
  table.remove(enemies, index)
end

local function findRandomPosition(enemies, playerEntity, enemyConfig, gameConfig)
  local maxAttempts = 20
  for attempt = 1, maxAttempts do
    local distance = enemyConfig.spawnDistanceMin + love.math.random() * enemyConfig.spawnDistanceMax
    local angle = love.math.random() * math.pi * 2
    local ex = playerEntity.x + math.cos(angle) * distance
    local ey = playerEntity.y + math.sin(angle) * distance

    -- Clamp to world boundaries
    ex = util.clamp(ex, -gameConfig.WORLD_SIZE + 100, gameConfig.WORLD_SIZE - 100)
    ey = util.clamp(ey, -gameConfig.WORLD_SIZE + 100, gameConfig.WORLD_SIZE - 100)

    -- Simple distance check
    local valid = true
    for _, existingEnemy in ipairs(enemies) do
      local dx = ex - existingEnemy.x
      local dy = ey - existingEnemy.y
      if util.len(dx, dy) < enemyConfig.minDistanceBetween then
        valid = false
        break
      end
    end

    if valid then
      return ex, ey, true
    end
  end
  return 0, 0, false
end

local function spawn(dt)
  local enemies = state.get("enemies")
  local playerEntity = state.get("player")
  local gameConfig = state.get("config").game

  if #enemies >= 5 then return end

  -- Spawn a cluster of 5 drones
  if #enemies == 0 then
    local clusterX, clusterY, valid = findRandomPosition(enemies, playerEntity, config.enemy, gameConfig)
    if valid then
      for i = 1, 5 do
        local offsetX = (love.math.random() * 2 - 1) * 50
        local offsetY = (love.math.random() * 2 - 1) * 50
        table.insert(enemies, M.new(clusterX + offsetX, clusterY + offsetY, playerEntity.level))
      end
    end
  end
end

function M.update(dt)
  spawn(dt)
  local enemies = state.get("enemies")
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    if e.state == "idle" then
      idleWander(e, dt)
    else
      aggroChaseAndShoot(e, dt)
    end
    keepInWorld(e)
    if e.hp <= 0 then M.kill(i) end
  end
end

function M.draw()
  local enemies = state.get("enemies")
  local uiConfig = config.ui
  -- Get enemy under mouse for hover effect
  local player = require("src.entities.player")
  local hoveredEnemy = player.getEnemyUnderMouse()
  
  for _,e in ipairs(enemies) do
    -- Use variant-specific colors
    local variantColor = e.color or {0.8, 0.1, 0.2} -- fallback to red
    local baseColor = {0.6, 0.05, 0.15} -- darkened for appendages
    local eyeColor = variantColor -- use variant color for eyes too

    -- Detailed drone design
    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.r)

    -- Main body (hexagonal core)
    love.graphics.setColor(variantColor[1], variantColor[2], variantColor[3], 1)
    love.graphics.polygon("fill",
      6, 0,    -- front point
      3, 4,    -- top right
      -3, 4,   -- top left
      -6, 0,   -- back point
      -3, -4,  -- bottom left
      3, -4    -- bottom right
    )

    -- Gun barrel
    love.graphics.setColor(0.3, 0.3, 0.3, 1) -- dark gray
    love.graphics.rectangle("fill", 6, -1, 8, 2) -- gun barrel extending forward
    
    -- Gun tip (darker)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 13, -0.5, 2, 1)

    -- Engine exhausts (back of drone)
    love.graphics.setColor(0.2, 0.2, 0.4, 1) -- dark blue
    love.graphics.circle("fill", -6, 2, 1.5)  -- top engine
    love.graphics.circle("fill", -6, -2, 1.5) -- bottom engine
    
    -- Engine glow effect
    love.graphics.setColor(0.4, 0.6, 1.0, 0.6) -- light blue glow
    love.graphics.circle("fill", -6, 2, 1)
    love.graphics.circle("fill", -6, -2, 1)

    -- Core details (sensor/cockpit area)
    love.graphics.setColor(0.1, 0.1, 0.2, 1) -- very dark
    love.graphics.circle("fill", 0, 0, 2)
    
    -- Sensor eye
    love.graphics.setColor(1, 0.2, 0.2, 0.8) -- red sensor
    love.graphics.circle("fill", 2, 0, 1)

    -- Wing struts
    love.graphics.setColor(0.4, 0.4, 0.4, 1) -- gray
    love.graphics.setLineWidth(2)
    love.graphics.line(-1, 0, -1, 4)  -- top strut
    love.graphics.line(-1, 0, -1, -4) -- bottom strut
    love.graphics.setLineWidth(1)

    -- Small wing panels
    love.graphics.setColor(variantColor[1] * 0.7, variantColor[2] * 0.7, variantColor[3] * 0.7, 1)
    love.graphics.polygon("fill", -1, 4, 1, 3, 1, 5, -1, 5)   -- top wing
    love.graphics.polygon("fill", -1, -4, 1, -3, 1, -5, -1, -5) -- bottom wing

    love.graphics.pop()

    -- Draw interaction circle when mouse is hovering over this enemy
    if hoveredEnemy == e then
      local interactionRadius = e.radius + uiConfig.interactionRadiusOffset
      love.graphics.setColor(1, 1, 1, 0.8) -- white outline
      love.graphics.circle("line", e.x, e.y, interactionRadius)
      love.graphics.setColor(1, 1, 1, 0.3) -- semi-transparent white fill
      love.graphics.circle("line", e.x, e.y, interactionRadius + 2)
    end

    -- Health bar only (no shields) - Enhanced visibility
    local barWidth = uiConfig.barWidth
    local barHeight = uiConfig.barHeight
    local barX = e.x - barWidth/2
    local barY = e.y - e.radius - uiConfig.barOffsetY

    -- Health bar with glow effect for better visibility
    local healthPercent = math.max(0, math.min(1, e.hp/e.maxHP))

    -- Glow effect (semi-transparent background)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4)

    -- Background bar for health
    love.graphics.setColor(0.4, 0.4, 0.4, 1.0)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Health bar (red)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)

    -- Health border with glow
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    love.graphics.setLineWidth(1)

  end
  love.graphics.setColor(1,1,1,1)
end

return M
