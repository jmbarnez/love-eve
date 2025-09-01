
local ctx  = require("src.core.state")
local util = require("src.core.util")

local M = {}

function M.init()
  ctx.set("loots", {})
  ctx.set("bounties", {})
end

-- Create a physical loot item
function M.createItem(x, y, itemType, quantity)
  local loots = ctx.get("loots")
  local items = require("src.content.items.registry")

  -- Get item definition
  local itemDef = items.get(itemType)
  if not itemDef then return end

  local lootItem = {
    x = x,
    y = y,
    vx = 0, -- No initial velocity for immediate drops
    vy = 0,
    radius = 12, -- Larger radius for easier interaction
    life = 120, -- 2 minutes to collect
    itemType = itemType,
    quantity = quantity,
    spin = love.math.random() * 2 + 1,
    color = items.getColor(itemType),
    canInteract = true -- Enable interaction
  }

  table.insert(loots, lootItem)
end

function M.update(dt)
  local loots = ctx.get("loots")

  for i=#loots,1,-1 do
    local L = loots[i]
    L.life = L.life - dt
    if L.life <= 0 then table.remove(loots, i) goto continue end

    -- No automatic collection - players must manually left-click to collect items
    -- Items stay in place until collected or they expire

    ::continue::
  end
end

function M.draw()
  local loots = ctx.get("loots")
  local gameState = ctx.get("gameState")

  for _,L in ipairs(loots) do
    -- Use item-specific color if available, otherwise default gold
    local color = L.color or {0.9, 0.8, 0.3, 1}
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)

    love.graphics.push()
    love.graphics.translate(L.x, L.y)
    love.graphics.rotate(gameState.t * (L.spin or 1))

    if L.itemType then
      -- Draw item-specific icon
      local items = require("src.content.items.registry")
      local itemDef = items.get(L.itemType)

      if itemDef then
        -- Draw a simple item icon based on category
        if itemDef.category == "consumable" then
          -- Pill-shaped for consumables
          love.graphics.rectangle("fill", -6, -3, 12, 6, 3)
        elseif itemDef.category == "weapon_ammo" then
          -- Bullet-shaped for ammo
          love.graphics.rectangle("fill", -2, -6, 4, 12)
          love.graphics.circle("fill", 0, -6, 2)
        elseif itemDef.category == "rare" then
          -- Star-shaped for rare items
          for i = 1, 5 do
            local angle = (i - 1) * math.pi * 2 / 5
            local x1 = math.cos(angle) * 8
            local y1 = math.sin(angle) * 8
            local x2 = math.cos(angle + math.pi / 5) * 4
            local y2 = math.sin(angle + math.pi / 5) * 4
            love.graphics.line(0, 0, x1, y1)
            love.graphics.line(x1, y1, x2, y2)
          end
        else
          -- Generic box for equipment
          love.graphics.rectangle("fill", -6, -6, 12, 12)
        end
      end
    else
      -- Legacy credit/XP loot (diamond shape)
      love.graphics.polygon("fill", -8,0, 0,8, 8,0, 0,-8)
    end

    love.graphics.pop()

    -- Draw item label with name and quantity, e.g., "Rockets x2"
    do
      local items = require("src.content.items.registry")
      local itemName = (L.itemType and items.getName(L.itemType)) or "Item"
      local qty = L.quantity or 1
      local label = string.format("%s x%d", itemName, qty)
      love.graphics.setColor(1, 1, 1, 0.95)
      
      -- Use the small font for loot labels
      local smallFont = ctx.get("smallFont")
      local originalFont = love.graphics.getFont()
      love.graphics.setFont(smallFont)

      local f = smallFont
      local w = f:getWidth(label)
      love.graphics.printf(label, L.x - w/2, L.y + 12, w, "left")
      
      -- Restore the original font
      love.graphics.setFont(originalFont)
    end

    -- Draw interaction circle when mouse is hovering
    if L.canInteract then
      local mx, my = love.mouse.getPosition()
      local camera = ctx.get("camera")
      local gameState = ctx.get("gameState")
      local wx = camera.x + (mx - love.graphics.getWidth()/2)/gameState.zoom
      local wy = camera.y + (my - love.graphics.getHeight()/2)/gameState.zoom
      local dx = wx - L.x
      local dy = wy - L.y
      local dist = math.sqrt(dx*dx + dy*dy)

      if dist < L.radius then
        -- Draw interaction outline only (no tooltip)
        love.graphics.setColor(0.8, 0.9, 1.0, 0.8)
        love.graphics.circle("line", L.x, L.y, L.radius)
        love.graphics.setColor(0.8, 0.9, 1.0, 0.3)
        love.graphics.circle("fill", L.x, L.y, L.radius)
      end
    end
  end

  love.graphics.setColor(1,1,1,1)
end

-- Handle left-click collection of individual loot items
function M.handleLeftClick(x, y)
  local loots = ctx.get("loots")
  local camera = ctx.get("camera")
  local gameState = ctx.get("gameState")
  local wx = camera.x + (x - love.graphics.getWidth()/2)/gameState.zoom
  local wy = camera.y + (y - love.graphics.getHeight()/2)/gameState.zoom

  for i = #loots, 1, -1 do
    local L = loots[i]
    if L.canInteract then
      local dx = wx - L.x
      local dy = wy - L.y
      local dist = math.sqrt(dx*dx + dy*dy)

      if dist < L.radius then
        -- Collect this item
        local player = require("src.entities.player")
        player.addToInventory(L.itemType, L.quantity)

        -- No popup notification; label already shows name and quantity

        -- Remove the loot item
        table.remove(loots, i)
        return true -- Handled the click
      end
    end
  end

  return false -- No loot item clicked
end

return M
