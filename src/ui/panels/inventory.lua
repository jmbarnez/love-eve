local ctx = require("src.core.state")
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
  local items = require("src.models.items.registry")
  return items.getName(id)
end

local function totalInventoryItems()
  local inv = ctx.player and ctx.player.inventory or {}
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
  drag.update(Panel, 600, 400)
end

function Panel.draw()
  if not Panel.open or not ctx.player then return end
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local WND_W, WND_H = 600, 400
  if not Panel.x or not Panel.y then
    Panel.x = (W - WND_W) / 2
    Panel.y = (H - WND_H) / 2
  end

  local x, y = Panel.x, Panel.y
  local closeRect = window.draw(x, y, WND_W, WND_H, "INVENTORY")

  local mainX, mainY = x + 1, y + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H

  local itemSize, spacing = 64, 8
  local perRow = math.floor((mainW - 20) / (itemSize + spacing))
  local mx, my = love.mouse.getPosition()

  local list = {}
  for t, q in pairs(ctx.player.inventory or {}) do
    if q > 0 then table.insert(list, {type = t, quantity = q}) end
  end

<<<<<<< HEAD
=======
  local hoveredItems = {}  -- Store hovered items to draw tooltips last

>>>>>>> a91d4cc (Fixed combat and movement)
  for i, item in ipairs(list) do
    local row = math.floor((i - 1) / perRow)
    local col = (i - 1) % perRow
    local ix = mainX + 10 + col * (itemSize + spacing)
    local iy = mainY + row * (itemSize + spacing + 20)
    local hovered = mx >= ix and mx <= ix + itemSize and my >= iy and my <= iy + itemSize and Panel.open

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
    love.graphics.printf(getItemDisplayName(item.type), ix, iy + itemSize + 2, itemSize, "center")

    if hovered then
<<<<<<< HEAD
      tooltip.draw(item.type, item.quantity, mx + 15, my - 10)
    end
  end

=======
      table.insert(hoveredItems, {type = item.type, quantity = item.quantity, x = mx + 15, y = my - 10})
    end
  end

  -- Draw tooltips on top of all items
  for _, hoverData in ipairs(hoveredItems) do
    tooltip.draw(hoverData.type, hoverData.quantity, hoverData.x, hoverData.y)
  end

>>>>>>> a91d4cc (Fixed combat and movement)
  if #list == 0 then
    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.4)
    love.graphics.printf("Cargo hold is empty", mainX, mainY + 100, mainW, "center")
    love.graphics.printf("Items will appear here when collected", mainX, mainY + 120, mainW, "center")
  end

  -- Status bar at bottom
  love.graphics.setColor(0.04, 0.08, 0.12, 1)
  love.graphics.rectangle("fill", x, y + WND_H - 25, WND_W, 25)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.4)
  love.graphics.line(x, y + WND_H - 25, x + WND_W, y + WND_H - 25)
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  credit.draw(x + 10, y + WND_H - 18 - 2, 12)
  love.graphics.printf(string.format("Credits: %s", ctx.player.credits >= 1000000 and string.format("%.1fM", ctx.player.credits/1000000) or string.format("%.2f", ctx.player.credits)),
                      x + 26, y + WND_H - 18, 200, "left")
  love.graphics.printf(string.format("%d items", totalInventoryItems()), x, y + WND_H - 18, WND_W - 10, "right")
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.open then return false end
  local WND_W, WND_H = 600, 400
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
