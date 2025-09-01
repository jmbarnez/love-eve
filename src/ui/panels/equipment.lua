-- Ship Equipment Panel
-- Manage ship modules and upgrades like EVE Online

local state = require("src.core.state")
local theme = require("src.ui.theme")
local item_icon = require("src.ui.components.item_icon")
local tooltip = require("src.ui.components.tooltip")
local credit = require("src.content.credit")
local window = require("src.ui.components.window")
local drag = require("src.ui.core.drag")

local Panel = {
  open = false,
  x = nil,
  y = nil,
  drag = nil,
  showStats = true  -- Toggle for stats window within equipment panel
}

-- Equipment slot definitions
local EQUIPMENT_SLOTS = {
  "high_power_1", "high_power_2", "high_power_3", "high_power_4",
  "mid_power_1", "mid_power_2", "mid_power_3", "mid_power_4",
  "low_power_1", "low_power_2", "low_power_3",
  "rigs_1", "rigs_2", "rigs_3",
  "drone_1"
}

local SLOT_NAMES = {
  high_power_1 = "High Slot 1", high_power_2 = "High Slot 2", high_power_3 = "High Slot 3", high_power_4 = "High Slot 4",
  mid_power_1 = "Mid Slot 1", mid_power_2 = "Mid Slot 2", mid_power_3 = "Mid Slot 3", mid_power_4 = "Mid Slot 4",
  low_power_1 = "Low Slot 1", low_power_2 = "Low Slot 2", low_power_3 = "Low Slot 3",
  rigs_1 = "Rig Slot 1", rigs_2 = "Rig Slot 2", rigs_3 = "Rig Slot 3",
  drone_1 = "Drone Bay"
}

local function getPlayerEquipment()
  local playerEntity = state.get("player")
  return playerEntity.equipment or {}
end

local function updatePlayerStats()
  local playerEntity = state.get("player")
  local equipment = getPlayerEquipment()

  -- Reset to base stats
  local ship = require("src.content.ships.starter")
  playerEntity.maxHP = ship.maxHP
  playerEntity.maxShield = ship.maxShield
  playerEntity.maxEnergy = ship.maxEnergy
  playerEntity.damage = ship.damage
  playerEntity.maxSpeed = ship.maxSpeed
  playerEntity.accel = ship.accel
  playerEntity.energyRegen = 10  -- Base value
  playerEntity.shieldRegen = 15   -- Base value

  -- Apply equipment bonuses
  for slotId, itemId in pairs(equipment) do
    local itemDef = require("src.content.items.registry").get(itemId)
    if itemDef and itemDef.slot_type and itemDef.stats then
      -- Only apply if item can fit in this slot
      if (itemDef.slot_type == "high_power" and string.find(slotId, "high_power")) or
         (itemDef.slot_type == "mid_power" and string.find(slotId, "mid_power")) or
         (itemDef.slot_type == "low_power" and string.find(slotId, "low_power")) or
         (itemDef.slot_type == "rig" and string.find(slotId, "rigs")) then

        for stat, value in pairs(itemDef.stats) do
          if playerEntity[stat] then
            playerEntity[stat] = playerEntity[stat] + value
          end
        end
      end
    end
  end
end

function Panel.toggle()
  Panel.open = not Panel.open
  if Panel.open then
    -- Update stats when opening panel
    updatePlayerStats()
  end
end

function Panel.isOpen()
  return Panel.open
end

function Panel.update(dt)
  if not Panel.open then return end
  drag.update(Panel, 700, 600)
end

function Panel.draw()
  local playerEntity = state.get("player")
  if not Panel.open or not playerEntity then return end

  local player = require("src.entities.player")
  local equipment = getPlayerEquipment()

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local WND_W, WND_H = 700, 600
  if not Panel.x or not Panel.y then
    Panel.x = (W - WND_W) / 2
    Panel.y = (H - WND_H) / 2
  end

  local x, y = Panel.x, Panel.y
  local closeRect = window.draw(x, y, WND_W, WND_H, "SHIP EQUIPMENT")

  local mainX, mainY = x + 1, y + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H

  local slotSize = 48
  local slotsPerRow = 4
  local spacing = 12
  local mx, my = love.mouse.getPosition()
  local totalStats = player.getTotalStats()
  local ship = require("src.content.ships.starter")

  -- Toggle stats button
  local toggleY = mainY + 5
  local toggleH = 20
  local toggleW = 80
  love.graphics.setColor(0.2, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", mainX + mainW - 90, toggleY, toggleW, toggleH, 3)
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", mainX + mainW - 90, toggleY, toggleW, toggleH, 3)
  love.graphics.setColor(1, 1, 1, 1)
  local fonts = require("src.core.state").get("fonts")
  if fonts and fonts.small then
    love.graphics.setFont(fonts.small)
  else
    love.graphics.setFont(love.graphics.newFont(12))
  end
  love.graphics.printf(Panel.showStats and "Hide Stats" or "Show Stats", mainX + mainW - 85, toggleY + 2, 70, "center")
  love.graphics.setFont(love.graphics.getFont()) -- Reset font

  -- Draw stats panel if enabled
  local statsPanelX = mainX + 250
  local statsPanelW = mainW - 270

  if Panel.showStats and mainW > 400 then  -- Only show stats if panel is wide enough
    -- Stats background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", statsPanelX, mainY + 30, statsPanelW, mainH - 60, 4)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", statsPanelX, mainY + 30, statsPanelW, mainH - 60, 4)

    -- Header
    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.9)
    love.graphics.printf("SHIP STATISTICS", statsPanelX + 10, mainY + 35, 150, "left")

    -- Current stats
    local statY = mainY + 60
    if fonts.small then
      love.graphics.setFont(fonts.small)
    else
      love.graphics.setFont(love.graphics.newFont(10))
    end
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf("HP: " .. string.format("%.0f", playerEntity.hp) .. "/" .. string.format("%.0f", totalStats.maxHP), statsPanelX + 15, statY, 120, "left")
    love.graphics.printf("Shield: " .. string.format("%.0f", playerEntity.shield) .. "/" .. string.format("%.0f", totalStats.maxShield), statsPanelX + 15, statY + 15, 120, "left")
    love.graphics.printf("Energy: " .. string.format("%.0f", playerEntity.energy) .. "/" .. string.format("%.0f", totalStats.maxEnergy), statsPanelX + 15, statY + 30, 120, "left")

    -- Combat stats
    local combatY = statY + 55
    love.graphics.setColor(0.8, 0.4, 0.2, 1)
    love.graphics.printf("Damage: +" .. string.format("%.0f", totalStats.damage - ship.damage), statsPanelX + 15, combatY, 120, "left")
    love.graphics.printf("Fire Rate: " .. string.format("%.1f", 60.0 / (playerEntity.fireCooldownMax or 0.2)), statsPanelX + 15, combatY + 15, 120, "left")

    -- Movement stats
    local moveY = combatY + 35
    love.graphics.setColor(0.4, 0.8, 0.4, 1)
    love.graphics.printf("Speed: +" .. string.format("%.0f", totalStats.maxSpeed - ship.maxSpeed), statsPanelX + 15, moveY, 120, "left")
    love.graphics.printf("Accel: +" .. string.format("%.0f", totalStats.accel - ship.accel), statsPanelX + 15, moveY + 15, 120, "left")

    -- Regeneration
    local regenY = moveY + 35
    love.graphics.setColor(1, 1, 0.3, 1)
    love.graphics.printf("Shield Regen: +" .. string.format("%.0f", totalStats.shieldRegen - 15), statsPanelX + 15, regenY, 120, "left")
    love.graphics.printf("Energy Regen: +" .. string.format("%.0f", totalStats.energyRegen - 10), statsPanelX + 15, regenY + 15, 120, "left")

    -- Equipment list
    local eqY = regenY + 40
    love.graphics.setColor(0.8, 0.8, 0.8, 0.8)
    love.graphics.printf("EQUIPMENT", statsPanelX + 15, eqY, 120, "left")
    eqY = eqY + 5

    local eqList = {}
    for slotId, itemId in pairs(equipment) do
      local itemDef = items.get(itemId)
      if itemDef then
        table.insert(eqList, itemDef.name)
      end
    end

    if #eqList > 0 then
      for i, eqName in ipairs(eqList) do
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.printf(eqName, statsPanelX + 20, eqY + i * 15, 120, "left")
      end
    else
      love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
      love.graphics.printf("No equipment", statsPanelX + 20, eqY + 15, 120, "left")
    end

    love.graphics.setFont(love.graphics.getFont()) -- Reset font
  end

  -- Draw equipment slots in EVE-like layout
  local hoveredSlots = {}
  local items = require("src.content.items.registry")
  local inventory = playerEntity.inventory or {}

  -- High slots (top row)
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("HIGH POWER SLOTS", mainX + 10, mainY + 10, mainW, "left")

  for i = 1, 4 do
    local slotId = "high_power_" .. i
    local row = 0
    local col = i - 1
    local slotX = mainX + 10 + col * (slotSize + spacing)
    local slotY = mainY + 30 + row * (slotSize + spacing)
    local hovered = mx >= slotX and mx <= slotX + slotSize and my >= slotY and my <= slotY + slotSize and Panel.open

    -- Slot background
    love.graphics.setColor(0.1, 0.2, 0.4, 0.8) -- Dark blue for high slots
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
    love.graphics.setColor(0.3, 0.5, 0.8, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4)

    -- Equipment highlight
    if equipment[slotId] then
      local itemDef = items.get(equipment[slotId])
      if itemDef then
        love.graphics.setColor(0.5, 0.7, 1.0, 0.3)
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
        item_icon.draw(equipment[slotId], slotX + slotSize/2, slotY + slotSize/2, slotSize * 0.7)
      end
    else
      -- Empty slot indicator
      love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", slotX + slotSize/2 - 8, slotY + slotSize/2 - 8, 16, 16)
    end

    if hovered then
      table.insert(hoveredSlots, {
        slotId = slotId,
        x = mx + 15,
        y = my - 10,
        equipped = equipment[slotId],
        available = inventory
      })
    end
  end

  -- Mid slots (second row)
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("MID POWER SLOTS", mainX + 10, mainY + 110, mainW, "left")

  for i = 1, 4 do
    local slotId = "mid_power_" .. i
    local row = 1
    local col = i - 1
    local slotX = mainX + 10 + col * (slotSize + spacing)
    local slotY = mainY + 30 + row * (slotSize + spacing)
    local hovered = mx >= slotX and mx <= slotX + slotSize and my >= slotY and my <= slotY + slotSize and Panel.open

    love.graphics.setColor(0.3, 0.1, 0.2, 0.8) -- Dark purple for mid slots
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
    love.graphics.setColor(0.6, 0.3, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4)

    if equipment[slotId] then
      local itemDef = items.get(equipment[slotId])
      if itemDef then
        love.graphics.setColor(0.7, 0.5, 0.8, 0.3)
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
        item_icon.draw(equipment[slotId], slotX + slotSize/2, slotY + slotSize/2, slotSize * 0.7)
      end
    else
      love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", slotX + slotSize/2 - 8, slotY + slotSize/2 - 8, 16, 16)
    end

    if hovered then
      table.insert(hoveredSlots, {
        slotId = slotId,
        x = mx + 15,
        y = my - 10,
        equipped = equipment[slotId],
        available = inventory
      })
    end
  end

  -- Low slots (third row - using only 3 for frigate)
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("LOW POWER SLOTS", mainX + 10, mainY + 190, mainW, "left")

  for i = 1, 3 do
    local slotId = "low_power_" .. i
    local row = 2
    local col = i - 1
    local slotX = mainX + 10 + col * (slotSize + spacing)
    local slotY = mainY + 30 + row * (slotSize + spacing)
    local hovered = mx >= slotX and mx <= slotX + slotSize and my >= slotY and my <= slotY + slotSize and Panel.open

    love.graphics.setColor(0.1, 0.3, 0.1, 0.8) -- Dark green for low slots
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
    love.graphics.setColor(0.3, 0.6, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4)

    if equipment[slotId] then
      local itemDef = items.get(equipment[slotId])
      if itemDef then
        love.graphics.setColor(0.5, 0.8, 0.5, 0.3)
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
        item_icon.draw(equipment[slotId], slotX + slotSize/2, slotY + slotSize/2, slotSize * 0.7)
      end
    else
      love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", slotX + slotSize/2 - 8, slotY + slotSize/2 - 8, 16, 16)
    end

    if hovered then
      table.insert(hoveredSlots, {
        slotId = slotId,
        x = mx + 15,
        y = my - 10,
        equipped = equipment[slotId],
        available = inventory
      })
    end
  end

  -- Rigs and drone bay (bottom section)
  local rigY = mainY + 280
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("RIGS", mainX + 10, rigY, mainW, "left")

  for i = 1, 3 do
    local slotId = "rigs_" .. i
    local col = i - 1
    local slotX = mainX + 10 + col * (slotSize + spacing)
    local slotY = rigY + 20
    local hovered = mx >= slotX and mx <= slotX + slotSize and my >= slotY and my <= slotY + slotSize and Panel.open

    love.graphics.setColor(0.4, 0.2, 0.2, 0.8) -- Dark red for rig slots
    love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
    love.graphics.setColor(0.7, 0.4, 0.4, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4)

    if equipment[slotId] then
      local itemDef = items.get(equipment[slotId])
      if itemDef then
        love.graphics.setColor(0.9, 0.6, 0.6, 0.3)
        love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
        item_icon.draw(equipment[slotId], slotX + slotSize/2, slotY + slotSize/2, slotSize * 0.7)
      end
    else
      love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", slotX + slotSize/2 - 8, slotY + slotSize/2 - 8, 16, 16)
    end

    if hovered then
      table.insert(hoveredSlots, {
        slotId = slotId,
        x = mx + 15,
        y = my - 10,
        equipped = equipment[slotId],
        available = inventory
      })
    end
  end

  -- Drone bay
  local droneY = rigY + 80
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("DRONE BAY", mainX + 10, droneY, mainW, "left")

  local slotId = "drone_1"
  local slotX = mainX + 10
  local slotY = droneY + 20
  local hovered = mx >= slotX and mx <= slotX + slotSize and my >= slotY and my <= slotY + slotSize and Panel.open

  love.graphics.setColor(0.2, 0.2, 0.4, 0.8) -- Dark blue-purple for drone bay
  love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
  love.graphics.setColor(0.4, 0.4, 0.7, 1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", slotX, slotY, slotSize, slotSize, 4)

  if equipment[slotId] then
    local itemDef = items.get(equipment[slotId])
    if itemDef then
      love.graphics.setColor(0.6, 0.6, 0.9, 0.3)
      love.graphics.rectangle("fill", slotX, slotY, slotSize, slotSize, 4)
      item_icon.draw(equipment[slotId], slotX + slotSize/2, slotY + slotSize/2, slotSize * 0.7)
    end
  else
    love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", slotX + slotSize/2 - 8, slotY + slotSize/2 - 8, 16, 16)
  end

  if hovered then
    table.insert(hoveredSlots, {
      slotId = slotId,
      x = mx + 15,
      y = my - 10,
      equipped = equipment[slotId],
      available = inventory
    })
  end

  -- Draw tooltips
  for _, slotData in ipairs(hoveredSlots) do
    local tooltipText = SLOT_NAMES[slotData.slotId] or slotData.slotId
    if slotData.equipped then
      local itemDef = items.get(slotData.equipped)
      if itemDef then
        tooltipText = tooltipText .. "\n" .. itemDef.name .. "\n" .. (itemDef.description or "")
      end
    else
      tooltipText = tooltipText .. "\nEmpty\nRight-click to equip"
    end
    tooltip.draw(slotData.equipped or "empty_slot", 1, slotData.x, slotData.y)
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
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.open then return false end
  local WND_W, WND_H = 700, 600
  local wx, wy = Panel.x or 0, Panel.y or 0
  if window.isInTitle(x, y, wx, wy, WND_W) then
    if window.isInRect(x, y, window.closeRect(wx, wy, WND_W)) then
      Panel.open = false
      return true
    end
    drag.start(Panel, x, y)
    return true
  end

  -- Check toggle stats button
  local mainX, mainY = wx + 1, wy + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H
  local toggleY = mainY + 5
  local toggleH = 20
  local toggleW = 80

  if x >= mainX + mainW - 90 and x <= mainX + mainW - 90 + toggleW and
     y >= toggleY and y <= toggleY + toggleH then
    Panel.showStats = not Panel.showStats
    return true
  end

  if x >= wx and x <= wx + WND_W and y >= wy and y <= wy + WND_H then
    return true
  end
  return false
end

function Panel.mousereleased(x, y, button)
  if button == 1 and Panel.drag then
    drag.stop(Panel)
    return true
  elseif button == 2 then
    -- Right-click for context menu
    local slotSize = 48
    local slotsPerRow = 4
    local spacing = 12
    local wx, wy = Panel.x or 0, Panel.y or 0
    local mainX, mainY = wx + 1, wy + window.TITLE_H

    -- Convert screen coordinates to panel coordinates
    local px, py = x - wx, y - wy

    -- Check if clicked within a specific slot
    local equipment = getPlayerEquipment()
    local items = require("src.content.items.registry")

    -- Check high slots
    for i = 1, 4 do
      local slotId = "high_power_" .. i
      local row = 0
      local col = i - 1
      local slotX = 10 + col * (slotSize + spacing)
      local slotY = 30 + row * (slotSize + spacing)

      if px >= slotX and px <= slotX + slotSize and py >= slotY and py <= slotY + slotSize then
        if equipment[slotId] then
          -- Unequip item
          local player = require("src.entities.player")
          local success, message = player.unequipItem(slotId)
          if success then
            print("Unequipped: " .. message)
          end
        else
          -- Show message about equipping
          print("Right-click to equip items - not implemented yet")
        end
        return true
      end
    end

    -- Check mid slots
    for i = 1, 4 do
      local slotId = "mid_power_" .. i
      local row = 1
      local col = i - 1
      local slotX = 10 + col * (slotSize + spacing)
      local slotY = 30 + row * (slotSize + spacing)

      if px >= slotX and px <= slotX + slotSize and py >= slotY and py <= slotY + slotSize then
        if equipment[slotId] then
          local player = require("src.entities.player")
          local success, message = player.unequipItem(slotId)
          if success then
            print("Unequipped: " .. message)
          end
        else
          print("Right-click to equip items - not implemented yet")
        end
        return true
      end
    end

    -- Check low slots
    for i = 1, 3 do
      local slotId = "low_power_" .. i
      local row = 2
      local col = i - 1
      local slotX = 10 + col * (slotSize + spacing)
      local slotY = 30 + row * (slotSize + spacing)

      if px >= slotX and px <= slotX + slotSize and py >= slotY and py <= slotY + slotSize then
        if equipment[slotId] then
          local player = require("src.entities.player")
          local success, message = player.unequipItem(slotId)
          if success then
            print("Unequipped: " .. message)
          end
        else
          print("Right-click to equip items - not implemented yet")
        end
        return true
      end
    end

    -- Check rig slots
    local rigY = 280
    for i = 1, 3 do
      local slotId = "rigs_" .. i
      local col = i - 1
      local slotX = 10 + col * (slotSize + spacing)
      local slotY = rigY + 20

      if px >= slotX and px <= slotX + slotSize and py >= slotY and py <= slotY + slotSize then
        if equipment[slotId] then
          local player = require("src.entities.player")
          local success, message = player.unequipItem(slotId)
          if success then
            print("Unequipped: " .. message)
          end
        else
          print("Right-click to equip items - not implemented yet")
        end
        return true
      end
    end

    -- Check drone bay
    local droneY = rigY + 80
    local slotId = "drone_1"
    local slotX = 10
    local slotY = droneY + 20

    if px >= slotX and px <= slotX + slotSize and py >= slotY and py <= slotY + slotSize then
      if equipment[slotId] then
        local player = require("src.entities.player")
        local success, message = player.unequipItem(slotId)
        if success then
          print("Unequipped: " .. message)
        end
      else
        print("Right-click to equip items - not implemented yet")
      end
      return true
    end
  end
  return false
end

return Panel
