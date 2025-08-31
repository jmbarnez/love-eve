-- Ship Statistics Panel
-- Display computed ship statistics with equipment effects

local state = require("src.core.state")
local theme = require("src.ui.theme")
local credit = require("src.content.credit")
local window = require("src.ui.components.window")
local drag = require("src.ui.core.drag")
local player = require("src.entities.player")

local Panel = {
  open = false,
  x = nil,
  y = nil,
  drag = nil,
}

local BASE_STATS = {
  maxHP = 100,
  maxShield = 120,
  maxEnergy = 100,
  damage = 16,
  maxSpeed = 300,
  accel = 120,
  energyRegen = 10,
  shieldRegen = 15
}

function Panel.toggle()
  Panel.open = not Panel.open
end

function Panel.isOpen()
  return Panel.open
end

function Panel.update(dt)
  if not Panel.open then return end
  drag.update(Panel, 400, 550)
end

local function formatStatValue(value, isRegen)
  if isRegen then
    return string.format("%.1f/sec", value)
  else
    if value >= 1000 then
      return string.format("%.1fK", value / 1000)
    else
      return string.format("%.0f", value)
    end
  end
end

local function drawStatBar(label, baseValue, currentValue, maxValue, y, color)
  local x = Panel.x or 0
  local mainX = x + 20
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf(label, mainX, y, 120, "left")

  -- Base value in gray if different from current
  if baseValue ~= currentValue then
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.printf(string.format("(%s)", formatStatValue(baseValue, label:find("Regen"))), mainX, y, 300, "right")
  end

  -- Current value
  love.graphics.setColor(color[1] or 1, color[2] or 1, color[3] or 1, 1)
  love.graphics.printf(formatStatValue(currentValue, label:find("Regen")), mainX, y, 180, "right")

  -- Progress bar background
  love.graphics.setColor(0.15, 0.15, 0.15, 1)
  love.graphics.rectangle("fill", mainX + 190, y, 150, 16, 3)

  -- Progress bar fill
  local percentage = maxValue > 0 and (currentValue / maxValue) or 0
  percentage = math.min(percentage, 1) -- Cap at 100%
  love.graphics.setColor(color[1] or 0.5, color[2] or 0.8, color[3] or 1, 0.8)
  love.graphics.rectangle("fill", mainX + 190, y, 150 * percentage, 16, 3)

  -- Progress bar border
  love.graphics.setColor(0.4, 0.4, 0.4, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", mainX + 190, y, 150, 16, 3)
end

function Panel.draw()
  local playerEntity = state.get("player")
  if not Panel.open or not playerEntity then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local WND_W, WND_H = 400, 550
  if not Panel.x or not Panel.y then
    Panel.x = W - WND_W - 10
    Panel.y = 50
  end

  local x, y = Panel.x, Panel.y
  local closeRect = window.draw(x, y, WND_W, WND_H, "SHIP STATISTICS")

  local mainX, mainY = x + 1, y + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H

  -- Get current and total stats
  local totalStats = player.getTotalStats()
  local equipment = player.getEquipment()
  local items = require("src.models.items.registry")

  -- Draw ship header
  local ship = require("src.content.ships.starter")
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf(ship.name, mainX + 20, mainY + 15, mainW, "center")

  local levelText = string.format("Level %d", playerEntity.level or 1)
  love.graphics.printf(levelText, mainX + 20, mainY + 35, mainW, "center")
  love.graphics.setColor(0.6, 0.6, 0.6, 0.7)
  love.graphics.printf(string.format("XP: %d/%d", playerEntity.xp or 0, playerEntity.xpToNext or 100), mainX + 20, mainY + 55, mainW, "center")

  -- Separator line
  love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
  love.graphics.line(mainX + 20, mainY + 80, mainX + mainW - 20, mainY + 80)

  -- Combat Statistics
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("COMBAT", mainX + 20, mainY + 95, mainW, "center")

  local yOffset = 115
  drawStatBar("Hull", BASE_STATS.maxHP, playerEntity.hp or BASE_STATS.maxHP, totalStats.maxHP, mainY + yOffset, {0.8, 0.2, 0.2})
  yOffset = yOffset + 25
  drawStatBar("Shield", BASE_STATS.maxShield, playerEntity.shield or BASE_STATS.maxShield, totalStats.maxShield, mainY + yOffset, {0.2, 0.4, 1.0})
  yOffset = yOffset + 25
  drawStatBar("Energy", BASE_STATS.maxEnergy, playerEntity.energy or BASE_STATS.maxEnergy, totalStats.maxEnergy, mainY + yOffset, {1, 1, 0.3})
  yOffset = yOffset + 25
  love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
  love.graphics.line(mainX + 20, mainY + yOffset + 5, mainX + mainW - 20, mainY + yOffset + 5)

  -- Weapon Systems
  yOffset = yOffset + 15
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("WEAPON SYSTEMS", mainX + 20, mainY + yOffset, mainW, "center")
  yOffset = yOffset + 20

  -- Damage
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("Damage", mainX + 20, mainY + yOffset, 120, "left")
  local damageBonus = totalStats.damage - BASE_STATS.damage
  if damageBonus ~= 0 then
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.printf(string.format("(%d)", BASE_STATS.damage), mainX + 20, mainY + yOffset, 300, "right")
  end
  if damageBonus > 0 then
    love.graphics.setColor(0.2, 1.0, 0.3, 1)
  elseif damageBonus < 0 then
    love.graphics.setColor(1.0, 0.3, 0.3, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.printf(string.format("%.0f", totalStats.damage), mainX + 20, mainY + yOffset, 180, "right")
  yOffset = yOffset + 25

  -- Fire Rate
  local fireRate = (1.0 / (playerEntity.fireCooldownMax or 0.2)) * 60
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("Fire Rate", mainX + 20, mainY + yOffset, 120, "left")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(string.format("%.1f RPS", fireRate), mainX + 20, mainY + yOffset, 180, "right")
  yOffset = yOffset + 25

  love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
  love.graphics.line(mainX + 20, mainY + yOffset + 5, mainX + mainW - 20, mainY + yOffset + 5)

  -- Propulsion Systems
  yOffset = yOffset + 15
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("PROPULSION", mainX + 20, mainY + yOffset, mainW, "center")
  yOffset = yOffset + 20

  -- Max Speed
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("Max Speed", mainX + 20, mainY + yOffset, 120, "left")
  local speedBonus = totalStats.maxSpeed - BASE_STATS.maxSpeed
  if speedBonus ~= 0 then
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.printf(string.format("(%d)", BASE_STATS.maxSpeed), mainX + 20, mainY + yOffset, 300, "right")
  end
  if speedBonus > 0 then
    love.graphics.setColor(0.2, 1.0, 0.3, 1)
  elseif speedBonus < 0 then
    love.graphics.setColor(1.0, 0.3, 0.3, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.printf(formatStatValue(totalStats.maxSpeed, false), mainX + 20, mainY + yOffset, 180, "right")
  yOffset = yOffset + 25

  -- Acceleration
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("Acceleration", mainX + 20, mainY + yOffset, 120, "left")
  local accelBonus = totalStats.accel - BASE_STATS.accel
  if accelBonus ~= 0 then
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.printf(string.format("(%d)", BASE_STATS.accel), mainX + 20, mainY + yOffset, 300, "right")
  end
  if accelBonus > 0 then
    love.graphics.setColor(0.2, 1.0, 0.3, 1)
  elseif accelBonus < 0 then
    love.graphics.setColor(1.0, 0.3, 0.3, 1)
  else
    love.graphics.setColor(1, 1, 1, 1)
  end
  love.graphics.printf(formatStatValue(totalStats.accel, false), mainX + 20, mainY + yOffset, 180, "right")
  yOffset = yOffset + 25

  love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
  love.graphics.line(mainX + 20, mainY + yOffset + 5, mainX + mainW - 20, mainY + yOffset + 5)

  -- Capacitor & Shield Regeneration
  yOffset = yOffset + 15
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("REGENERATION", mainX + 20, mainY + yOffset, mainW, "center")
  yOffset = yOffset + 20

  drawStatBar("Shield Regen", BASE_STATS.shieldRegen, totalStats.shieldRegen, BASE_STATS.shieldRegen + 20, mainY + yOffset, {0.2, 0.4, 1.0})
  yOffset = yOffset + 25
  drawStatBar("Energy Regen", BASE_STATS.energyRegen, totalStats.energyRegen, BASE_STATS.energyRegen + 10, mainY + yOffset, {1, 1, 0.3})

  -- Equipment Summary
  yOffset = yOffset + 40
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
  love.graphics.printf("EQUIPPED MODULES", mainX + 20, mainY + yOffset, mainW, "center")
  yOffset = yOffset + 20

  local equipmentList = {}
  if next(equipment) then
    for slotId, itemId in pairs(equipment) do
      local itemDef = items.get(itemId)
      if itemDef then
        table.insert(equipmentList, {
          name = itemDef.name,
          slot = string.gsub(slotId, "_%d+", ""),
          stats = itemDef.stats or {}
        })
      end
    end

    -- Sort by slot type
    table.sort(equipmentList, function(a, b)
      local slotOrder = {high_power=1, mid_power=2, low_power=3, rigs=4, drone=5}
      return (slotOrder[a.slot] or 0) < (slotOrder[b.slot] or 0)
    end)

    for _, eq in ipairs(equipmentList) do
      -- Equipment name
      love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
      love.graphics.printf(eq.name, mainX + 20, mainY + yOffset, mainW - 40, "left")

      -- Equipment effect summary
      local effectText = ""
      for stat, value in pairs(eq.stats) do
        if eq.stats[stat] and eq.stats[stat] ~= 0 then
          effectText = effectText .. " +" .. eq.stats[stat] .. " " .. stat .. " "
        end
      end
      if effectText ~= "" then
        love.graphics.setColor(0.6, 0.9, 0.6, 0.8)
        love.graphics.printf(effectText, mainX + 20, mainY + yOffset + 15, mainW - 40, "left")
      end
      yOffset = yOffset + 35
    end
  else
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.printf("No modules equipped", mainX + 20, mainY + yOffset, mainW, "center")
  end

  -- Status bar
  love.graphics.setColor(0.04, 0.08, 0.12, 1)
  love.graphics.rectangle("fill", x, y + WND_H - 25, WND_W, 25)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.4)
  love.graphics.line(x, y + WND_H - 25, x + WND_W, y + WND_H - 25)
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  credit.draw(x + 10, y + WND_H - 18 - 2, 12)
  love.graphics.printf(string.format("Credits: %s", playerEntity.credits >= 1000000 and string.format("%.1fM", playerEntity.credits/1000000) or string.format("%.2f", playerEntity.credits)),
                      x + 26, y + WND_H - 18, 200, "left")

  love.graphics.setColor(1, 1, 1, 1)
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.open then return false end
  local WND_W, WND_H = 400, 550
  local wx, wy = Panel.x or 0, Panel.y or 0
  if window.isInTitle(x, y, wx, wy, WND_W) then
    if window.isInRect(x, y, window.closeRect(wx, wy, WND_W)) then
      Panel.open = false
      return true
    end
    drag.start(Panel, x, y)
    return true
  end
  if x >= wx and x <= wx + WND_W and y >= wy and y <= wy + WND_H then
    return true
  end
  return false
end

function Panel.mousereleased(x, y, button)
  if button == 1 and Panel.drag then drag.stop(Panel); return true end
  return false
end

return Panel
