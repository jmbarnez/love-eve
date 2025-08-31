local state = require("src.core.state")
local util = require("src.core.util")
local projectiles = require("src.systems.projectiles")
local config = require("src.core.config")

local M = {}
local respawnTimers = {standard = 0, aggressive = 0, sniper = 0, bruiser = 0}

-- Enemy variants for more variety (loaded from config)
local enemyVariants
local function loadEnemyVariants()
  local enemyConfig = config.enemy
  enemyVariants = {
    standard = {
      name = "standard",
      color = {0.8, 0.1, 0.2},
      baseSpeed = 1.0,
      fireRateBonus = 1.0,
      hpBonus = 1.0,
      damageBonus = 1.0,
      rangeBonus = 1.0,
      rewardBonus = 1.0,
      respawnTime = enemyConfig.respawnTimes.standard or 30.0
    },
    aggressive = {
      name = "aggressive",
      color = {0.9, 0.2, 0.2},
      baseSpeed = 1.3,
      fireRateBonus = 0.7,
      hpBonus = 0.8,
      damageBonus = 1.2,
      rangeBonus = 0.9,
      rewardBonus = 1.2,
      respawnTime = enemyConfig.respawnTimes.aggressive or 35.0
    },
    sniper = {
      name = "sniper",
      color = {0.6, 0.2, 0.8},
      baseSpeed = 0.8,
      fireRateBonus = 1.5,
      hpBonus = 0.6,
      damageBonus = 1.4,
      rangeBonus = 1.3,
      rewardBonus = 1.5,
      respawnTime = enemyConfig.respawnTimes.sniper or 45.0
    },
    bruiser = {
      name = "bruiser",
      color = {0.8, 0.4, 0.1},
      baseSpeed = 0.6,
      fireRateBonus = 2.0,
      hpBonus = 1.8,
      damageBonus = 1.5,
      rangeBonus = 0.8,
      rewardBonus = 1.8,
      respawnTime = enemyConfig.respawnTimes.bruiser or 50.0
    }
  }
end

-- Initialize variants
loadEnemyVariants()

local function preset(level)
  local enemyConfig = config.enemy
  local tier = math.min(1+math.floor((level-1)/3), 4)
  return enemyConfig.presets[tier]
end

function M.new(px,py, variantName, level)
  local enemyConfig = config.enemy
  local p = preset(level)
  local variant = enemyVariants[variantName]

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
    shield=enemyConfig.shield, maxShield=enemyConfig.shield,
    shieldRegen=enemyConfig.shieldRegen, shieldCooldown=0, shieldCDMax=enemyConfig.shieldCDMax,
    accel=200, maxSpeed=baseSpeed * speedVariation, friction=1.0,
    damage=baseDamage * damageVariation, fireCooldown=0, fireCooldownMax=baseFireRate * fireRateVariation,
    spread=0.01, lastShot=0, range=baseRange,
    bonus={tier=math.max(1, math.min(4, p.tier)), cr=p.creditReward * variant.rewardBonus, variant=variant},
    state="idle", -- becomes "aggro" only when attacked
    color=variant.color,
    variant=variant.name
  }
end

function M.init()
  state.set("enemies", {})
  state.set("lootBoxes", {})
  state.set("particles", {})
  state.set("notifications", {})
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
  local bullet = require("src.models.projectiles.types.bullet")
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

local function regen(e, dt)
  -- Removed - enemies don't have shields
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
  local items = require("src.models.items.registry")
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
  
  local contents = M.generateLootContents(e.bonus)
  if next(contents) ~= nil then
    -- Only drop loot box if there is actual loot
    local lootBoxes = state.get("lootBoxes")
    local lootBox = {
      x = e.x + (love.math.random()*2-1)*10,
      y = e.y + (love.math.random()*2-1)*10,
      radius = 12,
      type = "loot_box",
      life = 30,  -- Loot boxes last longer
      spin = (love.math.random()*2-1)*2,
      contents = contents
    }
    table.insert(lootBoxes, lootBox)
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

  if #enemies >= gameConfig.MAX_ENEMIES then return end

  -- Update individual respawn timers
  for variantType, timer in pairs(respawnTimers) do
    respawnTimers[variantType] = math.max(0, timer - dt)
    if respawnTimers[variantType] <= 0 then
      -- Choose random variant type for spawning
      local variantKeys = {}
      for k, _ in pairs(respawnTimers) do
        table.insert(variantKeys, k)
      end
      local spawnVariant = variantKeys[love.math.random(#variantKeys)]

      -- Find spawn position
      local x, y, valid = findRandomPosition(enemies, playerEntity, config.enemy, gameConfig)
      if valid then
        -- Spawn enemy
        table.insert(enemies, M.new(x, y, spawnVariant, playerEntity.level))

        -- Reset this variant's timer
        respawnTimers[variantType] = enemyVariants[variantType].respawnTime + (love.math.random() * 5 - 2.5) -- ±2.5 seconds variation
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
    -- No shield regen needed
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

    -- Alien enemy ship with organic, menacing design
    love.graphics.setColor(variantColor[1], variantColor[2], variantColor[3], 1)
    love.graphics.push()
    love.graphics.translate(e.x, e.y)
    love.graphics.rotate(e.r)

    -- Main body - irregular organic shape
    love.graphics.polygon("fill",
      8,0,    -6,6,   -4,3,   -8,0,   -4,-3,   -6,-6
    )

    -- Alien appendages/tentacles - adaptive color based on variant
    if e.variant == "bruiser" then
      love.graphics.setColor(0.6, 0.3, 0.1, 1) -- brown appendage for bruiser
    elseif e.variant == "sniper" then
      love.graphics.setColor(0.4, 0.1, 0.6, 1) -- purple appendage for sniper
    else
      love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 1) -- default dark appendage
    end
    love.graphics.polygon("fill", 2,4, -10,8, -6,5)
    love.graphics.polygon("fill", 2,-4, -10,-8, -6,-5)
    love.graphics.polygon("fill", -2,6, -12,10, -8,7)
    love.graphics.polygon("fill", -2,-6, -12,-10, -8,-7)

    -- Glowing alien eyes/sensors - color specific to variant
    if e.variant == "aggressive" then
      eyeColor = {1.0, 0.4, 0.2} -- bright orange for aggressive
    elseif e.variant == "sniper" then
      eyeColor = {1.0, 0.2, 1.0} -- magenta for sniper
    elseif e.variant == "bruiser" then
      eyeColor = {1.0, 0.6, 0.2} -- gold for bruiser
    else
      eyeColor = {1.0, 0.3, 0.1} -- orange for standard
    end
    love.graphics.setColor(eyeColor[1], eyeColor[2], eyeColor[3], 1)
    love.graphics.circle("fill", 4, 2, 1.5)
    love.graphics.circle("fill", 4, -2, 1.5)
    love.graphics.setColor(1.0, 0.8, 0.2, 0.8) -- yellow centers for all
    love.graphics.circle("fill", 4, 2, 0.8)
    love.graphics.circle("fill", 4, -2, 0.8)

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

    -- Health bar (green to red gradient)
    local r = 1 - healthPercent
    local g = healthPercent
    love.graphics.setColor(r, g, 0.2, 1)
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
