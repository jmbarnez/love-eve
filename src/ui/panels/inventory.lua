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
}

local function getItemDisplayName(id)
  local items = require("src.content.items.registry")
  return items.getName(id)
end

local function totalInventoryItems()
  local playerEntity = state.get("player")
  local inv = playerEntity and playerEntity.inventory or {}
  local n = 0
  for _, q in pairs(inv) do if q > 0 then n = n + q end end
  return n
end

function Panel.toggle()
  Panel.open = not Panel.open
end

function Panel.isOpen()
  return Panel.open
end

function Panel.update(dt)
  if not Panel.open then return end
  local ui_scale = window.ui_scale
  drag.update(Panel, 600 * ui_scale, 400 * ui_scale)
end

function Panel.draw()
  local playerEntity = state.get("player")
  if not Panel.open or not playerEntity then return end
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local ui_scale = window.ui_scale
  local WND_W, WND_H = 600 * ui_scale, 400 * ui_scale
  if not Panel.x or not Panel.y then
    Panel.x = (W - WND_W) / 2
    Panel.y = (H - WND_H) / 2
  end

  local x, y = Panel.x, Panel.y
  local closeRect = window.draw(x, y, WND_W, WND_H, "INVENTORY")

  local mainX, mainY = x + (1 * ui_scale), y + window.TITLE_H
  local mainW, mainH = WND_W - (1 * ui_scale), WND_H - window.TITLE_H

  local itemSize, spacing = 64 * ui_scale, 8 * ui_scale
  local perRow = math.floor((mainW - (20 * ui_scale)) / (itemSize + spacing))
  local mx, my = love.mouse.getPosition()

  local list = {}
  for t, q in pairs(playerEntity.inventory or {}) do
    if q > 0 then table.insert(list, {type = t, quantity = q}) end
  end

  local hoveredItems = {}  -- Store hovered items to draw tooltips last

  for i, item in ipairs(list) do
    local row = math.floor((i - 1) / perRow)
    local col = (i - 1) % perRow
    local ix = mainX + (10 * ui_scale) + col * (itemSize + spacing)
    local iy = mainY + row * (itemSize + spacing + (20 * ui_scale))
    local hovered = mx >= ix and mx <= ix + itemSize and my >= iy and my <= iy + itemSize and Panel.open

    love.graphics.setColor(hovered and theme.primary[1] or 0.06,
                           hovered and theme.primary[2] or 0.12,
                           hovered and theme.primary[3] or 0.18,
                           hovered and 0.3 or 0.8)
    love.graphics.rectangle("fill", ix, iy, itemSize, itemSize, 4 * ui_scale)
    love.graphics.setColor(hovered and theme.primary or theme.border)
    love.graphics.setLineWidth(1 * ui_scale)
    love.graphics.rectangle("line", ix, iy, itemSize, itemSize, 4 * ui_scale)

    item_icon.draw(item.type, ix + itemSize/2, iy + itemSize/2, itemSize * 0.6)

    love.graphics.setColor(1, 1, 1, 0.9)
    local qtyText = tostring(item.quantity)
    local f = love.graphics.getFont()
    local qtyW = f:getWidth(qtyText)
    local qtyH = f:getHeight()
    love.graphics.printf(qtyText, ix + itemSize - qtyW - (4 * ui_scale), iy + itemSize - qtyH - (2 * ui_scale), qtyW, "left")

    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
    love.graphics.printf(getItemDisplayName(item.type), ix, iy + itemSize + (2 * ui_scale), itemSize, "center")

    if hovered then
      table.insert(hoveredItems, {type = item.type, quantity = item.quantity, x = mx + 15, y = my - 10})
    end
  end

  -- Draw tooltips on top of all items
  for _, hoverData in ipairs(hoveredItems) do
    tooltip.draw(hoverData.type, hoverData.quantity, hoverData.x, hoverData.y)
  end

  if #list == 0 then
    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.4)
    love.graphics.printf("Cargo hold is empty", mainX, mainY + (100 * ui_scale), mainW, "center")
    love.graphics.printf("Items will appear here when collected", mainX, mainY + (120 * ui_scale), mainW, "center")
  end

  -- Status bar at bottom
  love.graphics.setColor(0.04, 0.08, 0.12, 1)
  love.graphics.rectangle("fill", x, y + WND_H - (25 * ui_scale), WND_W, 25 * ui_scale)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.4)
  love.graphics.line(x, y + WND_H - (25 * ui_scale), x + WND_W, y + WND_H - (25 * ui_scale))
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  credit.draw(x + (10 * ui_scale), y + WND_H - (18 * ui_scale) - (2 * ui_scale), 12 * ui_scale)
  love.graphics.printf(string.format("Credits: %s", playerEntity.credits >= 1000000 and string.format("%.1fM", playerEntity.credits/1000000) or string.format("%.2f", playerEntity.credits)),
                      x + (26 * ui_scale), y + WND_H - (18 * ui_scale), 200 * ui_scale, "left")
  love.graphics.printf(string.format("%d items", totalInventoryItems()), x, y + WND_H - (18 * ui_scale), WND_W - (10 * ui_scale), "right")
end

function Panel.mousepressed(x, y, button)
  if not Panel.open then return false end
  local ui_scale = window.ui_scale
  local WND_W, WND_H = 600 * ui_scale, 400 * ui_scale
  local wx, wy = Panel.x or 0, Panel.y or 0

  if button == 1 then
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
  elseif button == 2 then -- Right-click
    local playerEntity = state.get("player")
    local mainX, mainY = wx + (1 * ui_scale), wy + window.TITLE_H
    local mainW, mainH = WND_W - (1 * ui_scale), WND_H - window.TITLE_H
    local itemSize, spacing = 64 * ui_scale, 8 * ui_scale
    local perRow = math.floor((mainW - (20 * ui_scale)) / (itemSize + spacing))

    local list = {}
    for t, q in pairs(playerEntity.inventory or {}) do
      if q > 0 then table.insert(list, {type = t, quantity = q}) end
    end

    for i, item in ipairs(list) do
      local row = math.floor((i - 1) / perRow)
      local col = (i - 1) % perRow
      local ix = mainX + (10 * ui_scale) + col * (itemSize + spacing)
      local iy = mainY + row * (itemSiz + spacing + (20 * ui_scale))
      
      if x >= ix and x <= ix + itemSize and y >= iy and y <= iy + itemSize then
        if not playerEntity.docked then
            print("You must be docked to change equipment.")
            return true
        end
        local player = require("src.entities.player")
        local items = require("src.content.items.registry")
        local itemDef = items.get(item.type)
        if itemDef and itemDef.category == "equipment" then
          -- Find first available slot
          local equipmentPanel = require("src.ui.panels.equipment")
          local slotId = equipmentPanel.findAvailableSlot(itemDef.slot_type)
          if slotId then
            player.equipItem(slotId, item.type)
            return true
          end
        end
      end
    end
  end
  return false
end

function Panel.mousereleased(x, y, button)
  if button == 1 and Panel.drag then drag.stop(Panel); return true end
  return false
end

return Panel
