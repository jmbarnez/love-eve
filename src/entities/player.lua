local state = require("src.core.state")
local util = require("src.core.util")
local ship = require("src.content.ships.starter")
local config = require("src.core.config")
local modules = require("src.systems.modules")

local M = {}

function M.new()
  local playerConfig = config.player
  return {
    x=0,y=0, vx=0,vy=0, r=0,
    radius=playerConfig.radius,
    accel=playerConfig.accel,
    maxSpeed=playerConfig.maxSpeed,
    friction=playerConfig.friction,
    energy=playerConfig.energy, maxEnergy=playerConfig.maxEnergy, energyRegen=playerConfig.energyRegen,
    hp=10, maxHP=10,
    shield=0, maxShield=0, shieldRegen=playerConfig.shieldRegen, shieldCooldown=0, shieldCDMax=playerConfig.shieldCDMax,
    fireCooldown=0, -- seconds until next shot allowed
    fireCooldownMax=playerConfig.fireCooldownMax, -- fixed cooldown for default attack
    spread=playerConfig.spread,
    lastShot=0,
    credits=0.00,
    inventory={}, -- Player inventory
    equipment={}, -- Player equipment slots
    level=1,
    xp=0,
    xpToNext=100,
    docked=false,
    moveTarget=nil,
    attackTarget=nil, -- Auto attack target
    moveMarker={x=0, y=0, timer=0}, -- Temporary visual marker for right-click movement
  }
end

function M.init()
  local playerEntity = M.new()
  -- Start near station but not docked
  local station = state.get("station") or {x=0,y=0}
  playerEntity.x = station.x + 150  -- offset to the right
  playerEntity.y = station.y
  playerEntity.docked = false
  playerEntity.r = math.pi  -- face left towards station
  
  state.set("player", playerEntity)
  
  -- Initialize inventory with starting items
  M.addToInventory("repair_kit", 5, true)
  M.addToInventory("shield_booster", 2, true)
  M.addToInventory("alien_tech", 1, true)
  M.addToInventory("mining_laser", 1, true)
  M.addToInventory("salvage_laser", 1, true)

  -- Initialize with basic turret (user can remove it later)
  M.addToInventory("basic_turret", 1, true)
  M.equipItem("high_power_1", "basic_turret")
end

local function applyMovement(dt)
  local playerEntity = state.get("player")
  local playerConfig = config.player
  -- Handle right-click movement
  if playerEntity.moveTarget then
    local dx = playerEntity.moveTarget.x - playerEntity.x
    local dy = playerEntity.moveTarget.y - playerEntity.y
    local dist = util.len(dx, dy)
    if dist < 15 then
      -- Reached destination
      playerEntity.moveTarget = nil
      playerEntity.vx = playerEntity.vx * 0.8  -- Slow down when reaching target
      playerEntity.vy = playerEntity.vy * 0.8
    else
      -- Move toward target
      local ux, uy = dx / dist, dy / dist
      local desiredSpeed = math.min(playerEntity.maxSpeed, dist * 2)  -- Slow down as we approach
      local dvx, dvy = ux * desiredSpeed - playerEntity.vx, uy * desiredSpeed - playerEntity.vy
      playerEntity.vx = playerEntity.vx + dvx * 1.5 * dt  -- Responsive movement
      playerEntity.vy = playerEntity.vy + dvy * 1.5 * dt

      -- Only face movement direction when not recently firing
      if playerEntity.lastShot > 0.5 then  -- 0.5 second grace period after firing
        playerEntity.r = math.atan2(dy, dx)
      end

      -- Energy consumption for movement (reduced from 12 to 6 per second)
      playerEntity.energy = math.max(0, playerEntity.energy - playerConfig.energyCostMovement * dt)
    end
  else
    -- No target, regenerate energy faster
    playerEntity.energy = math.min(playerEntity.maxEnergy, playerEntity.energy + playerEntity.energyRegen * dt)
  end
end

-- Function to set move target from right-click
function M.setMoveTarget(x, y)
  local playerEntity = state.get("player")
  if not playerEntity.docked then
    playerEntity.moveTarget = {x = x, y = y}
    -- Set temporary visual marker (like League of Legends right-click effect)
    local uiConfig = config.ui
    playerEntity.moveMarker = {x = x, y = y, timer = uiConfig.moveMarkerDuration} -- 1.25 second duration (twice as fast)
  end
end

-- Function to set attack target
function M.setAttackTarget(enemy)
  local playerEntity = state.get("player")
  if not playerEntity.docked then
    playerEntity.attackTarget = enemy
  end
end

local function clampPhysics(dt)
  local playerEntity = state.get("player")
  local gameConfig = state.get("config").game
  local gameState = state.get("gameState")
  local p = playerEntity
  local spd = util.len(p.vx, p.vy)
  if spd > p.maxSpeed then local s = p.maxSpeed/spd; p.vx = p.vx*s; p.vy = p.vy*s end

  p.x = p.x + p.vx * dt
  p.y = p.y + p.vy * dt

  -- keep in world
  local W = gameConfig.WORLD_SIZE
  if p.x < -W then p.x = -W; p.vx = math.abs(p.vx) end
  if p.x > W then p.x = W; p.vx = -math.abs(p.vx) end
  if p.y < -W then p.y = -W; p.vy = math.abs(p.vy) end
  if p.y > W then p.y = W; p.vy = -math.abs(p.vy) end

  -- face mouse
  local mx,my = love.mouse.getPosition()
  local lg = love.graphics
  local camera = state.get("camera")
  local wx = camera.x + (mx - lg.getWidth()/2)/gameState.zoom
  local wy = camera.y + (my - lg.getHeight()/2)/gameState.zoom
  p.r = math.atan2(wy - p.y, wx - p.x)
end

local function regen(dt)
  local p = state.get("player")
  if p.shieldCooldown>0 then p.shieldCooldown = p.shieldCooldown - dt end
  if p.shieldCooldown<=0 then
    p.shield = math.min(p.maxShield, p.shield + p.shieldRegen*dt)
  end
end

local function shooting(dt)
  local playerEntity = state.get("player")
  local p = playerEntity
  p.lastShot = math.min(p.lastShot + dt, 1.0)
  p.fireCooldown = math.max(0, (p.fireCooldown or 0) - dt)

  if p.attackTarget and p.attackTarget.hp <= 0 then
    p.attackTarget = nil
  end
end

function M.fire_turret(turret)
    local playerEntity = state.get("player")
    local p = playerEntity
    local playerConfig = config.player

    -- Clear target if it's dead (don't auto-select new target)
    if p.attackTarget and p.attackTarget.hp <= 0 then
        p.attackTarget = nil
    end

    -- Only fire if we have a manually selected target
    if p.attackTarget and p.attackTarget.hp > 0 then
        local dx = p.attackTarget.x - p.x
        local dy = p.attackTarget.y - p.y
        local dist = util.len(dx, dy)
        if turret.range and dist < turret.range and p.fireCooldown <= 0 then
            p.r = math.atan2(dy, dx)

            local projectiles = require("src.systems.projectiles")
            local bullet = require("src.content.projectiles.types.bullet")
            
            -- Create a temporary weapon definition that merges turret and bullet properties
            local weapon = util.merge(bullet, turret)

            projectiles.createFromOwner(p, weapon, p.attackTarget)

            p.energy = math.max(0, p.energy - playerConfig.energyCostPerShot)
            p.lastShot = 0
            p.fireCooldown = p.fireCooldownMax
            
            local camera = state.get("camera")
            camera.shake = math.min(0.05, camera.shake + 0.01)
            return true
        end
    end
    return false
end

function M.update(dt)
  applyMovement(dt)
  clampPhysics(dt)
  regen(dt)
  shooting(dt)
  
  -- Update move marker timer
  local playerEntity = state.get("player")
  local uiConfig = config.ui
  if playerEntity.moveMarker.timer > 0 then
    playerEntity.moveMarker.timer = playerEntity.moveMarker.timer - dt
  end
end

function M.addToInventory(itemType, quantity, silent)
  local playerEntity = state.get("player")
  if not playerEntity.inventory[itemType] then
    playerEntity.inventory[itemType] = 0
  end
  playerEntity.inventory[itemType] = playerEntity.inventory[itemType] + quantity

  if not silent then
    -- Create a notification
    local items = require("src.content.items.registry")
    local itemName = items.getName(itemType)
    local notifications = state.get("notifications")
    table.insert(notifications, {
      text = string.format("+%d %s", quantity, itemName),
      timer = 3, -- seconds
      x = playerEntity.x,
      y = playerEntity.y - playerEntity.radius - 10
    })
  end
end

function M.removeFromInventory(itemType, quantity)
  local playerEntity = state.get("player")
  if playerEntity.inventory[itemType] and playerEntity.inventory[itemType] >= quantity then
    playerEntity.inventory[itemType] = playerEntity.inventory[itemType] - quantity
    return true
  end
  return false
end

function M.getInventoryCount(itemType)
  local playerEntity = state.get("player")
  return playerEntity.inventory[itemType] or 0
end

function M.hasItem(itemType, quantity)
  local playerEntity = state.get("player")
  return (playerEntity.inventory[itemType] or 0) >= quantity
end

function M.getEnemyUnderMouse()
  local mx, my = love.mouse.getPosition()
  local uiConfig = config.ui

  -- Convert screen coordinates to world coordinates
  local camera = state.get("camera")
  local gameState = state.get("gameState")
  local wx = camera.x + (mx - love.graphics.getWidth()/2) / gameState.zoom
  local wy = camera.y + (my - love.graphics.getHeight()/2) / gameState.zoom

  -- Check each enemy to see if mouse is over it
  local enemies = state.get("enemies")
  for _, enemy in ipairs(enemies) do
    local dx = wx - enemy.x
    local dy = wy - enemy.y
    local distance = util.len(dx, dy)

    -- Use a slightly larger radius for mouse interaction (same as the green circle)
    if distance <= enemy.radius + uiConfig.interactionRadiusOffset then
      return enemy
    end
  end

  return nil
end

local function drawShield()
  local playerEntity = state.get("player")
  local projectileConfig = config.projectiles
  local p = playerEntity
  
  -- Only show shield when it's actively blocking damage (shieldCooldown > 0)
  if p.shield > 0 and p.shieldCooldown > 0 then
    local shieldRadius = p.radius + projectileConfig.shieldRadiusOffset
    
    -- Simple blue circle shield
    love.graphics.setColor(0.2, 0.4, 1.0, 0.6)
    love.graphics.circle("line", p.x, p.y, shieldRadius)
  end
  
  love.graphics.setColor(1,1,1,1)
end

function M.draw()
  local playerEntity = state.get("player")
  local uiConfig = config.ui

  -- Draw temporary move marker (expanding ring) UNDER the player
  if playerEntity.moveMarker.timer > 0 then
    local marker = playerEntity.moveMarker
    local progress = 1 - (marker.timer / uiConfig.moveMarkerDuration) -- 0 to 1 as it fades
    local alpha = marker.timer / uiConfig.moveMarkerDuration -- Fade from 1.0 to 0.0 over 1.25 seconds

    -- Expanding ring that starts small and grows
    local minRadius = 5
    local maxRadius = 40
    local currentRadius = minRadius + (maxRadius - minRadius) * progress

    -- Ring color with fade
    love.graphics.setColor(0.8, 0.9, 1.0, alpha * 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", marker.x, marker.y, currentRadius)

    love.graphics.setColor(1, 1, 1, 1)
  end

  ship.draw(playerEntity.x, playerEntity.y, playerEntity.r, ship.scale, util.len(playerEntity.vx, playerEntity.vy)/playerEntity.maxSpeed)
  drawShield()

  -- Draw attack target indicator
  if playerEntity.attackTarget and playerEntity.attackTarget.hp > 0 then
    love.graphics.setColor(1.0, 0.5, 0.0, 0.8) -- Orange indicator
    love.graphics.circle("line", playerEntity.attackTarget.x, playerEntity.attackTarget.y, playerEntity.attackTarget.radius + uiConfig.attackIndicatorRadiusOffset)
    love.graphics.setColor(1,1,1,1)
  end
end

function M.regenDocked(dt)
  local playerEntity = state.get("player")
  local playerConfig = config.player
  -- Faster regen when docked
  playerEntity.hp = math.min(playerEntity.maxHP, playerEntity.hp + 20*dt)
  playerEntity.shield = math.min(playerEntity.maxShield, playerEntity.shield + 30*dt)
  playerEntity.energy = math.min(playerEntity.maxEnergy, playerEntity.energy + 40*dt)
end

-- Equipment management functions
function M.equipItem(slotId, itemId)
  local playerEntity = state.get("player")
  local items = require("src.content.items.registry")
  local itemDef = items.get(itemId)

  if not itemDef then return false, "Unknown item" end
  if not itemDef.slot_type then return false, "Item is not equipment" end

  -- Check if item can fit in this slot
  local slotType = ""
  if string.find(slotId, "high_power") then slotType = "high_power"
  elseif string.find(slotId, "mid_power") then slotType = "mid_power"
  elseif string.find(slotId, "low_power") then slotType = "low_power"
  elseif string.find(slotId, "rigs") then slotType = "rig"
  elseif string.find(slotId, "drone") then slotType = "drone"
  end

  if itemDef.slot_type ~= slotType then return false, "Item cannot fit in this slot" end

  -- Check if player has this item in inventory
  if not playerEntity.inventory[itemId] or playerEntity.inventory[itemId] < 1 then
    return false, "Item not in inventory"
  end

  -- Unequip existing item if any
  if playerEntity.equipment[slotId] then
    local existingItem = playerEntity.equipment[slotId]
    M.addToInventory(existingItem, 1) -- Add back to inventory
  end

  -- Equip the new item
  playerEntity.equipment[slotId] = itemId
  M.removeFromInventory(itemId, 1)

  -- Update player stats
  local ship = require("src.content.ships.starter")
  playerEntity.maxHP = ship.maxHP
  playerEntity.maxShield = ship.maxShield
  playerEntity.maxEnergy = ship.maxEnergy
  playerEntity.maxSpeed = ship.maxSpeed
  playerEntity.accel = ship.accel
  playerEntity.energyRegen = 10
  playerEntity.shieldRegen = 15
  
  -- Always restore HP to full when maxHP changes
  playerEntity.hp = playerEntity.maxHP

  -- Apply equipment bonuses
  for eqSlotId, eqItemId in pairs(playerEntity.equipment or {}) do
    local eqItemDef = items.get(eqItemId)
    if eqItemDef and eqItemDef.slot_type and eqItemDef.stats then
      local eqSlotType = ""
      if string.find(eqSlotId, "high_power") then eqSlotType = "high_power"
      elseif string.find(eqSlotId, "mid_power") then eqSlotType = "mid_power"
      elseif string.find(eqSlotId, "low_power") then eqSlotType = "low_power"
      elseif string.find(eqSlotId, "rigs") then eqSlotType = "rig"
      elseif string.find(eqSlotId, "drone") then eqSlotType = "drone"
      end

      if eqItemDef.slot_type == eqSlotType then
        for stat, value in pairs(eqItemDef.stats) do
          if playerEntity[stat] then
            playerEntity[stat] = playerEntity[stat] + value
          end
        end
      end
    end
  end

  modules.recalculate_modules()
  return true, "Equipped " .. itemDef.name
end

function M.unequipItem(slotId)
  local playerEntity = state.get("player")
  local items = require("src.content.items.registry")
  local itemId = playerEntity.equipment[slotId]
  local itemDef = items.get(itemId)

  if not itemId then return false, "Slot is empty" end

  -- Unequip the item and add back to inventory
  M.addToInventory(itemId, 1)
  playerEntity.equipment[slotId] = nil

  -- Reset player stats to base ship stats
  local ship = require("src.content.ships.starter")
  playerEntity.maxHP = ship.maxHP
  playerEntity.maxShield = ship.maxShield
  playerEntity.maxEnergy = ship.maxEnergy
  playerEntity.maxSpeed = ship.maxSpeed
  playerEntity.accel = ship.accel
  playerEntity.energyRegen = 10
  playerEntity.shieldRegen = 15
  
  -- Always restore HP to full when maxHP changes
  playerEntity.hp = playerEntity.maxHP

  -- Re-apply all remaining equipment bonuses
  for eqSlotId, eqItemId in pairs(playerEntity.equipment or {}) do
    local eqItemDef = items.get(eqItemId)
    if eqItemDef and eqItemDef.slot_type and eqItemDef.stats then
      local eqSlotType = ""
      if string.find(eqSlotId, "high_power") then eqSlotType = "high_power"
      elseif string.find(eqSlotId, "mid_power") then eqSlotType = "mid_power"
      elseif string.find(eqSlotId, "low_power") then eqSlotType = "low_power"
      elseif string.find(eqSlotId, "rigs") then eqSlotType = "rig"
      elseif string.find(eqSlotId, "drone") then eqSlotType = "drone"
      end

      if eqItemDef.slot_type == eqSlotType then
        for stat, value in pairs(eqItemDef.stats) do
          if playerEntity[stat] then
            playerEntity[stat] = playerEntity[stat] + value
          end
        end
      end
    end
  end

  modules.recalculate_modules()
  return true, "Unequipped " .. (itemDef and itemDef.name or itemId)
end

function M.getEquipment()
  local playerEntity = state.get("player")
  return playerEntity.equipment or {}
end

function M.getTotalStats()
  local playerEntity = state.get("player")
  local ship = require("src.content.ships.starter")
  return {
    maxHP = playerEntity.maxHP or 100,
    maxShield = playerEntity.maxShield or 120,
    maxEnergy = playerEntity.maxEnergy or 100,
    maxSpeed = playerEntity.maxSpeed or 300,
    accel = playerEntity.accel or 120,
    energyRegen = playerEntity.energyRegen or 10,
    shieldRegen = playerEntity.shieldRegen or 15,
    damage = ship.damage or 16 -- Base ship damage
  }
end

return M
