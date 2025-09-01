local state = require("src.core.state")
local util = require("src.core.util")
local projectiles = require("src.systems.projectiles")
local config = require("src.core.config")

local M = {}

-- Station modules
local modules = {
  core = {
    name = "Core Reactor",
    hp = 1000,
    maxHP = 1000,
    radius = 60,
    regenRate = 5,
    color = {0.8, 1.0, 1.0}
  },
  defense_turret_1 = {
    name = "Defense Turret Alpha",
    hp = 200,
    maxHP = 200,
    radius = 15,
    damage = 15,
    fireRate = 1.5,
    range = 400,
    color = {0.6, 0.9, 1.0},
    offset = {x = 150, y = 0}
  },
  defense_turret_2 = {
    name = "Defense Turret Beta",
    hp = 200,
    maxHP = 200,
    radius = 15,
    damage = 15,
    fireRate = 1.5,
    range = 400,
    color = {0.6, 0.9, 1.0},
    offset = {x = 0, y = 150}
  },
  defense_turret_3 = {
    name = "Defense Turret Gamma",
    hp = 200,
    maxHP = 200,
    radius = 15,
    damage = 15,
    fireRate = 1.5,
    range = 400,
    color = {0.6, 0.9, 1.0},
    offset = {x = -150, y = 0}
  },
  defense_turret_4 = {
    name = "Defense Turret Delta",
    hp = 200,
    maxHP = 200,
    radius = 15,
    damage = 15,
    fireRate = 1.5,
    range = 400,
    color = {0.6, 0.9, 1.0},
    offset = {x = 0, y = -150}
  },
  repair_bay = {
    name = "Repair Bay",
    hp = 300,
    maxHP = 300,
    radius = 40,
    repairRate = 20,
    color = {0.7, 0.95, 1.0},
    offset = {x = 200, y = 0}
  },
  shield_generator = {
    name = "Shield Generator",
    hp = 400,
    maxHP = 400,
    radius = 25,
    shieldRegen = 15,
    color = {0.5, 0.8, 1.0},
    offset = {x = -100, y = 100}
  }
}

function M.new()
  local station = {
    x = 0,
    y = 0,
    radius = 280,
    modules = {},
    shield = 500,
    maxShield = 500,
    shieldRegen = 10,
    shieldCooldown = 0,
    shieldCDMax = 3.0,
    dockingRadius = 320,
    rotation = 0,
    lastRepair = 0,
    defenseTargets = {}
  }

  -- Initialize modules
  for moduleId, moduleData in pairs(modules) do
    station.modules[moduleId] = {
      hp = moduleData.hp,
      maxHP = moduleData.maxHP,
      lastShot = 0,
      fireCooldown = 0,
      active = true
    }
  end

  return station
end

function M.init()
  local station = M.new()
  state.set("station", station)
end

function M.update(dt)
  local station = state.get("station")
  if not station then return end

  station.rotation = station.rotation + dt * 0.05

  -- Shield regeneration
  if station.shieldCooldown > 0 then
    station.shieldCooldown = math.max(0, station.shieldCooldown - dt)
  end
  if station.shieldCooldown <= 0 then
    station.shield = math.min(station.maxShield, station.shield + station.shieldRegen * dt)
  end

  -- Module regeneration
  for moduleId, module in pairs(station.modules) do
    local moduleData = modules[moduleId]
    if module.active and module.hp < module.maxHP then
      module.hp = math.min(module.maxHP, module.hp + moduleData.regenRate * dt)
    end
  end

  -- Defense system
  M.updateDefense(dt)

  -- Repair docked player
  M.repairDockedPlayer(dt)
end

function M.updateDefense(dt)
  local station = state.get("station")
  local enemies = state.get("enemies") or {}

  -- Clear old targets
  station.defenseTargets = {}

  -- Find enemies in range
  for _, enemy in ipairs(enemies) do
    local dx = enemy.x - station.x
    local dy = enemy.y - station.y
    local dist = util.len(dx, dy)

    if dist < 600 then -- Defense range
      table.insert(station.defenseTargets, enemy)
    end
  end

  -- Update turrets
  for moduleId, module in pairs(station.modules) do
    if string.find(moduleId, "defense_turret") and module.active then
      M.updateTurret(moduleId, module, dt)
    end
  end
end

function M.updateTurret(moduleId, module, dt)
  local station = state.get("station")
  local moduleData = modules[moduleId]

  if #station.defenseTargets == 0 then return end

  -- Find closest target
  local closestTarget = nil
  local closestDist = math.huge

  for _, enemy in ipairs(station.defenseTargets) do
    local offsetX = moduleData.offset and moduleData.offset.x or 0
    local offsetY = moduleData.offset and moduleData.offset.y or 0
    local turretX = station.x + offsetX
    local turretY = station.y + offsetY
    local dx = enemy.x - turretX
    local dy = enemy.y - turretY
    local dist = util.len(dx, dy)

    if dist < closestDist and dist <= moduleData.range then
      closestTarget = enemy
      closestDist = dist
    end
  end

  if not closestTarget then return end

  -- Update cooldowns
  module.lastShot = math.min(module.lastShot + dt, 1.0)
  module.fireCooldown = math.max(0, module.fireCooldown - dt)

  -- Fire if ready
  if module.fireCooldown <= 0 then
    local offsetX = moduleData.offset and moduleData.offset.x or 0
    local offsetY = moduleData.offset and moduleData.offset.y or 0
    local turretX = station.x + offsetX
    local turretY = station.y + offsetY

    -- Create turret projectile
    local bullet = require("src.content.projectiles.types.bullet")
    local turretOwner = {
      x = turretX,
      y = turretY,
      damage = moduleData.damage,
      vx = 0,
      vy = 0
    }

    projectiles.createFromOwner(turretOwner, bullet, closestTarget)

    module.lastShot = 0
    module.fireCooldown = moduleData.fireRate
  end
end

function M.repairDockedPlayer(dt)
  local station = state.get("station")
  local playerEntity = state.get("player")

  if not playerEntity.docked then return end

  local dx = playerEntity.x - station.x
  local dy = playerEntity.y - station.y
  local dist = util.len(dx, dy)

  if dist > station.dockingRadius then
    playerEntity.docked = false
    return
  end

  -- Repair player using repair bay
  local repairBay = station.modules.repair_bay
  if repairBay and repairBay.active then
    local repairRate = modules.repair_bay.repairRate

    -- Repair HP
    if playerEntity.hp < playerEntity.maxHP then
      playerEntity.hp = math.min(playerEntity.maxHP, playerEntity.hp + repairRate * dt)
    end

    -- Repair shield
    if playerEntity.shield < playerEntity.maxShield then
      playerEntity.shield = math.min(playerEntity.maxShield, playerEntity.shield + repairRate * dt)
    end

    -- Repair energy
    if playerEntity.energy < playerEntity.maxEnergy then
      playerEntity.energy = math.min(playerEntity.maxEnergy, playerEntity.energy + repairRate * dt)
    end
  end
end

-- Bounty claiming system
function M.canClaimBounties()
  local playerEntity = state.get("player")
  if not playerEntity.docked then return false end

  local dx = playerEntity.x - state.get("station").x
  local dy = playerEntity.y - state.get("station").y
  local dist = util.len(dx, dy)

  return dist <= state.get("station").dockingRadius
end

function M.claimBounties()
  if not M.canClaimBounties() then return 0 end

  local wreckage = require("src.entities.wreckage")
  local totalClaimed = wreckage.claimBounties()

  -- No UI notification; credits already added to player

  return totalClaimed
end

function M.getTotalBounty()
  local wreckage = require("src.entities.wreckage")
  return wreckage.getTotalBounty()
end

function M.onHit(damage, hitX, hitY)
  local station = state.get("station")

  -- Check shield first
  if station.shield > 0 then
    station.shield = math.max(0, station.shield - damage)
    station.shieldCooldown = station.shieldCDMax
    return
  end

  -- Find closest module to hit location
  local closestModule = nil
  local closestDist = math.huge

  for moduleId, module in pairs(station.modules) do
    local moduleData = modules[moduleId]
    local offsetX = moduleData.offset and moduleData.offset.x or 0
    local offsetY = moduleData.offset and moduleData.offset.y or 0
    local moduleX = station.x + offsetX
    local moduleY = station.y + offsetY
    local dx = hitX - moduleX
    local dy = hitY - moduleY
    local dist = util.len(dx, dy)

    if dist < closestDist then
      closestModule = moduleId
      closestDist = dist
    end
  end

  -- Damage the module
  if closestModule then
    local module = station.modules[closestModule]
    module.hp = math.max(0, module.hp - damage)

    -- Deactivate if destroyed
    if module.hp <= 0 then
      module.active = false
    end
  end
end

function M.draw()
  local station = state.get("station")
  if not station then return end

  local t = love.timer.getTime()

  -- Draw docking bay glow
  love.graphics.setColor(0.3, 0.8, 1.0, 0.08)
  love.graphics.circle("fill", station.x, station.y, station.dockingRadius)

  -- Draw shield if active
  if station.shield > 0 and station.shieldCooldown > 0 then
    love.graphics.setColor(0.2, 0.4, 1.0, 0.6)
    love.graphics.circle("line", station.x, station.y, station.radius + 20)
  end

  -- Draw modules
  for moduleId, module in pairs(station.modules) do
    local moduleData = modules[moduleId]
    local offsetX = moduleData.offset and moduleData.offset.x or 0
    local offsetY = moduleData.offset and moduleData.offset.y or 0
    local moduleX = station.x + offsetX
    local moduleY = station.y + offsetY

    -- Module color based on health
    local healthPercent = module.hp / module.maxHP
    local r = moduleData.color[1] * (0.5 + 0.5 * healthPercent)
    local g = moduleData.color[2] * (0.5 + 0.5 * healthPercent)
    local b = moduleData.color[3] * (0.5 + 0.5 * healthPercent)

    love.graphics.setColor(r, g, b, 1)

    -- Draw module based on type
    if string.find(moduleId, "defense_turret") then
      M.drawTurret(moduleX, moduleY, moduleData, station.rotation)
    elseif moduleId == "core" then
      M.drawCore(moduleX, moduleY, moduleData, t)
    elseif moduleId == "repair_bay" then
      M.drawRepairBay(moduleX, moduleY, moduleData, station.rotation)
    elseif moduleId == "shield_generator" then
      M.drawShieldGenerator(moduleX, moduleY, moduleData, t)
    end

    -- Health bar for damaged modules
    if module.hp < module.maxHP then
      M.drawModuleHealthBar(moduleX, moduleY, module, moduleData)
    end
  end

  -- Draw connecting structures
  M.drawConnectingStructures(station, t)

  love.graphics.setColor(1, 1, 1, 1)
end

function M.drawTurret(x, y, moduleData, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Turret base
  love.graphics.circle("fill", 0, 0, moduleData.radius)

  -- Turret barrel
  love.graphics.rectangle("fill", 0, -3, 25, 6)

  love.graphics.pop()
end

function M.drawCore(x, y, moduleData, t)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(t * 0.1)

  -- Outer ring
  love.graphics.circle("line", 0, 0, moduleData.radius)

  -- Inner rings
  for i = 1, 3 do
    local ringRadius = moduleData.radius * (0.3 + i * 0.2)
    love.graphics.circle("line", 0, 0, ringRadius)
  end

  -- Pulsing core
  love.graphics.setColor(0.2, 0.9, 1.0, 0.6 + 0.4 * math.sin(t * 3))
  love.graphics.circle("fill", 0, 0, 15)
  love.graphics.setColor(1.0, 1.0, 1.0, 0.8 + 0.2 * math.sin(t * 3))
  love.graphics.circle("fill", 0, 0, 8)

  love.graphics.pop()
end

function M.drawRepairBay(x, y, moduleData, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation * 0.5)

  -- Bay structure
  love.graphics.rectangle("fill", -moduleData.radius, -moduleData.radius/2,
                         moduleData.radius * 2, moduleData.radius)

  -- Repair beams
  for i = 1, 4 do
    love.graphics.push()
    love.graphics.rotate(i * math.pi / 2)
    love.graphics.line(0, 0, moduleData.radius, 0)
    love.graphics.pop()
  end

  love.graphics.pop()
end

function M.drawShieldGenerator(x, y, moduleData, t)
  love.graphics.push()
  love.graphics.translate(x, y)

  -- Generator core
  love.graphics.circle("fill", 0, 0, moduleData.radius)

  -- Energy rings
  for i = 1, 2 do
    local ringRadius = moduleData.radius + i * 8
    local alpha = 0.5 + 0.3 * math.sin(t * 2 + i)
    love.graphics.setColor(0.5, 0.8, 1.0, alpha)
    love.graphics.circle("line", 0, 0, ringRadius)
  end

  love.graphics.pop()
end

function M.drawModuleHealthBar(x, y, module, moduleData)
  local barWidth = 40
  local barHeight = 4
  local barX = x - barWidth/2
  local barY = y - moduleData.radius - 8

  local healthPercent = module.hp / module.maxHP

  -- Background
  love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
  love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

  -- Health bar
  local r = 1 - healthPercent
  local g = healthPercent
  love.graphics.setColor(r, g, 0.2, 1)
  love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight)

  -- Border
  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
end

function M.drawConnectingStructures(station, t)
  love.graphics.setColor(0.7, 0.9, 1.0, 0.6)

  -- Draw connections between modules
  for moduleId, module in pairs(station.modules) do
    local moduleData = modules[moduleId]
    if moduleData.offset then
      love.graphics.line(station.x, station.y,
                        station.x + moduleData.offset.x,
                        station.y + moduleData.offset.y)
    end
  end

  -- Draw outer defensive ring
  love.graphics.push()
  love.graphics.translate(station.x, station.y)
  love.graphics.rotate(station.rotation)

  for i = 1, 12 do
    love.graphics.push()
    love.graphics.rotate(i * math.pi / 6)
    love.graphics.translate(station.radius, 0)
    love.graphics.rectangle("line", -8, -24, 16, 48)
    love.graphics.pop()
  end

  love.graphics.pop()
end

return M
