-- Loot Box Entity
-- Handles loot boxes that require player interaction to open

local ctx = require("src.core.state")
local util = require("src.core.util")

local M = {}

function M.update(dt)
  for i = #ctx.lootBoxes, 1, -1 do
    local box = ctx.lootBoxes[i]
    box.life = box.life - dt
    if box.life <= 0 then
      table.remove(ctx.lootBoxes, i)
      goto continue
    end

    -- Check for player interaction (close enough and pressing E)
    local player = ctx.get("player")
    local dx, dy = player.x - box.x, player.y - box.y
    local dist = util.len(dx, dy)

    if dist < 50 then  -- Interaction range
      box.canInteract = true
      if love.keyboard.isDown("e") and not box.interacted then
        box.interacted = true
        -- Open container window instead of instant loot
        ctx.set("currentContainer", box)
        ctx.set("containerOpen", true)
        -- Do not remove box yet; wait for window close
        goto continue
      end
    else
      box.canInteract = false
    end

    ::continue::
  end

  -- Update notifications
  for i = #ctx.notifications, 1, -1 do
    local notif = ctx.notifications[i]
    notif.life = notif.life - dt
    if notif.life <= 0 then
      table.remove(ctx.notifications, i)
    end
  end
end

function M.showNotification(text, color)
  table.insert(ctx.notifications, {
    text = text,
    color = color or {1, 1, 1, 1},
    life = 3.0,  -- Show for 3 seconds
    y = 0  -- Will be set when drawing
  })
end

function M.openLootBox(box)
  local items = require("src.models.items.registry")
  local player = require("src.entities.player")
  local playerEntity = ctx.get("player")

  if box.contents.credits then
    playerEntity.credits = playerEntity.credits + box.contents.credits
    M.showNotification("+" .. string.format("%.2f", box.contents.credits) .. " Credits", {0.9, 0.8, 0.3, 1})
  end
  
  for itemId, itemData in pairs(box.contents) do
    if itemId ~= "credits" then
      local quantity = itemData.quantity or 1
      player.addToInventory(itemId, quantity)
      local color = items.getColor(itemId)
      local name = items.getName(itemId)
      M.showNotification("+" .. quantity .. " " .. name, color)
    end
  end

  for k = 1, 20 do
    table.insert(ctx.particles, {
      x = box.x,
      y = box.y,
      vx = (love.math.random() * 2 - 1) * 120,
      vy = (love.math.random() * 2 - 1) * 120,
      life = 0.8 + love.math.random() * 0.4,
      color = {1, 0.8, 0.2, 1}
    })
  end

  local camera = ctx.get("camera")
  camera.shake = math.max(camera.shake, 0.2)
end

function M.draw()
  local gameState = ctx.get("gameState")
  for _, box in ipairs(ctx.lootBoxes) do
    love.graphics.push()
    love.graphics.translate(box.x, box.y)
    love.graphics.rotate(gameState.t * (box.spin or 1))

    -- Simple basic container visual
    love.graphics.setColor(0.7, 0.7, 0.8, 1)
    love.graphics.rectangle("fill", -8, -8, 16, 16, 2)
    
    love.graphics.setColor(0.9, 0.9, 1, 1)
    love.graphics.rectangle("line", -8, -8, 16, 16, 2)

    -- Simple interaction glow
    if box.canInteract then
      love.graphics.setColor(0.3, 0.8, 1, 0.6)
      love.graphics.rectangle("line", -10, -10, 20, 20, 3)
    end

    

    love.graphics.pop()
  end

  -- Draw notifications
  local startY = 100
  for i, notif in ipairs(ctx.notifications) do
    local alpha = math.min(1, notif.life * 2)  -- Fade in/out
    local y = startY + (i - 1) * 25
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", 10, y - 2, 200, 20, 4, 4)
    
    -- Text
    love.graphics.setColor(notif.color[1], notif.color[2], notif.color[3], notif.color[4] * alpha)
    love.graphics.printf(notif.text, 20, y, 180, "left")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return M
