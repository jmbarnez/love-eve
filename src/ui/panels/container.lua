local ctx = require("src.core.state")
local theme = require("src.ui.theme")
local item_icon = require("src.ui.components.item_icon")
local tooltip = require("src.ui.components.tooltip")
local loot_box = require("src.entities.loot_box")
local window = require("src.ui.components.window")
local drag = require("src.ui.core.drag")

local Panel = {
  x = nil,
  y = nil,
  drag = nil,
}

local function collectItems(container)
  local out = {}
  for itemType, data in pairs(container or {}) do
    local quantity, name
    if type(data) == "table" then
      quantity = data.quantity
      name = data.name or itemType
    elseif type(data) == "number" then
      quantity = data
      name = itemType
    end
    if quantity and quantity > 0 then
      table.insert(out, {type = itemType, quantity = quantity, name = name})
    end
  end
  return out
end

function Panel.isOpen()
  return ctx.containerOpen and ctx.currentContainer ~= nil
end

function Panel.update(dt)
  if not Panel.isOpen() then return end
  drag.update(Panel, 600, 400)
end

function Panel.draw()
  if not Panel.isOpen() then return end
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local WND_W, WND_H = 600, 400
  if not Panel.x or not Panel.y then
    Panel.x = (W - WND_W) / 2
    Panel.y = (H - WND_H) / 2
  end
  local x, y = Panel.x, Panel.y

  local closeRect = window.draw(x, y, WND_W, WND_H, "CONTAINER")

  local mainX, mainY = x + 1, y + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H
  local itemSize, spacing = 64, 8
  local perRow = math.floor((mainW - 20) / (itemSize + spacing))
  local mx, my = love.mouse.getPosition()

  local items = collectItems(ctx.currentContainer.contents)

<<<<<<< HEAD
=======
  local hoveredItems = {}  -- Store hovered items to draw tooltips last

>>>>>>> a91d4cc (Fixed combat and movement)
  for i, item in ipairs(items) do
    local row = math.floor((i - 1) / perRow)
    local col = (i - 1) % perRow
    local ix = mainX + 10 + col * (itemSize + spacing)
    local iy = mainY + row * (itemSize + spacing + 20)
    local hovered = mx >= ix and mx <= ix + itemSize and my >= iy and my <= iy + itemSize and Panel.isOpen()

    love.graphics.setColor(hovered and theme.primary[1] or 0.06,
                           hovered and theme.primary[2] or 0.12,
                           hovered and theme.primary[3] or 0.18,
                           hovered and 0.3 or 0.8)
    love.graphics.rectangle("fill", ix, iy, itemSize, itemSize, 4)
    love.graphics.setColor(hovered and theme.primary or theme.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", ix, iy, itemSize, itemSize, 4)

    item_icon.draw(item.type, ix + itemSize/2, iy + itemSize/2, itemSize * 0.6)

    love.graphics.setColor(1, 1, 1, 0.9)
    local qtyText = tostring(item.quantity)
    local f = love.graphics.getFont()
    local qtyW = f:getWidth(qtyText)
    local qtyH = f:getHeight()
    love.graphics.printf(qtyText, ix + itemSize - qtyW - 4, iy + itemSize - qtyH - 2, qtyW, "left")

    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
    love.graphics.printf(item.name, ix, iy + itemSize + 2, itemSize, "center")
<<<<<<< HEAD
    if hovered then tooltip.draw(item.type, item.quantity, mx + 15, my - 10) end
=======
    if hovered then
      table.insert(hoveredItems, {type = item.type, quantity = item.quantity, x = mx + 15, y = my - 10})
    end
  end

  -- Draw tooltips on top of all items
  for _, hoverData in ipairs(hoveredItems) do
    tooltip.draw(hoverData.type, hoverData.quantity, hoverData.x, hoverData.y)
>>>>>>> a91d4cc (Fixed combat and movement)
  end

  if #items > 0 then
    local btnW, btnH = 100, 30
    local bx = mainX + 10
    local by = mainY + mainH - btnH - 30
    love.graphics.setColor(0.04, 0.5, 0.2, 1)
    love.graphics.rectangle("fill", bx, by, btnW, btnH, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Take All", bx, by + 8, btnW, "center")
  end
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.isOpen() then return false end
  local WND_W, WND_H = 600, 400
  local wx, wy = Panel.x or 0, Panel.y or 0
  if window.isInTitle(x, y, wx, wy, WND_W) then
    if window.isInRect(x, y, window.closeRect(wx, wy, WND_W)) then
      ctx.containerOpen = false
      -- Remove current container (if still present)
      if ctx.currentContainer then
        for i, box in ipairs(ctx.lootBoxes) do
          if box == ctx.currentContainer then table.remove(ctx.lootBoxes, i); break end
        end
      end
      ctx.currentContainer = nil
      return true
    end
    drag.start(Panel, x, y)
    return true
  end

  -- Item click to take
  local mainX, mainY = wx + 1, wy + 30
  local mainW, mainH = 600 - 1, 400 - 30
  local itemSize, spacing = 64, 8
  local perRow = math.floor((mainW - 20) / (itemSize + spacing))
  local items = collectItems(ctx.currentContainer.contents or {})
  for i, item in ipairs(items) do
    local row = math.floor((i - 1) / perRow)
    local col = (i - 1) % perRow
    local ix = mainX + 10 + col * (itemSize + spacing)
    local iy = mainY + row * (itemSize + spacing + 20)
    if x >= ix and x <= ix + itemSize and y >= iy and y <= iy + itemSize then
      if item.type == "credits" then
        ctx.player.credits = ctx.player.credits + item.quantity
      else
        local player = require("src.entities.player")
        player.addToInventory(item.type, item.quantity)
      end
      ctx.currentContainer.contents[item.type] = nil
      loot_box.showNotification("+" .. item.quantity .. " " .. (item.name or item.type), {0, 1, 0, 1})
      return true
    end
  end

  -- Take all button
  if #items > 0 then
    local bx = mainX + 10
    local by = mainY + mainH - 30 - 30
    if x >= bx and x <= bx + 100 and y >= by and y <= by + 30 then
      for _, item in ipairs(items) do
        if item.type == "credits" then
          ctx.player.credits = ctx.player.credits + item.quantity
        else
          local player = require("src.entities.player")
          player.addToInventory(item.type, item.quantity)
        end
        ctx.currentContainer.contents[item.type] = nil
      end
      loot_box.showNotification("Took all items", {0, 1, 0, 1})
      return true
    end
  end

  if x >= wx and x <= wx + WND_W and y >= wy and y <= wy + WND_H then return true end
  return false
end

function Panel.mousereleased(x, y, button)
  if button == 1 and Panel.drag then drag.stop(Panel); return true end
  return false
end

return Panel
