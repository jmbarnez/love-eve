-- Loot Box Entity
-- Handles loot boxes that require player interaction to open

local ctx = require("src.core.ctx")
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
    local dx, dy = ctx.player.x - box.x, ctx.player.y - box.y
    local dist = util.len(dx, dy)

    if dist < 50 then  -- Interaction range
      box.canInteract = true
      if love.keyboard.isDown("e") and not box.interacted then
        box.interacted = true
        M.openLootBox(box)
        table.remove(ctx.lootBoxes, i)
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
  -- Add contents to player inventory
  if box.contents.credits then
    ctx.player.credits = ctx.player.credits + box.contents.credits
    M.showNotification("+" .. string.format("%.2f", box.contents.credits) .. " Credits", {0.9, 0.8, 0.3, 1})
  end
  
  if box.contents.rockets then
    local player = require("src.entities.player")
    player.addToInventory("rockets", box.contents.rockets.quantity)
    M.showNotification("+" .. box.contents.rockets.quantity .. " Rockets", {1, 0.5, 0, 1})
  end

  if box.contents.ammo then
    local player = require("src.entities.player")
    player.addToInventory("energy_cells", box.contents.ammo.quantity)
    M.showNotification("+" .. box.contents.ammo.quantity .. " Energy Cells", {0.5, 0.8, 1, 1})
  end

  if box.contents.repairKit then
    -- Heal player
    ctx.player.hp = math.min(ctx.player.maxHP, ctx.player.hp + 50)
    ctx.player.shield = math.min(ctx.player.maxShield, ctx.player.shield + 30)
    M.showNotification("+50 HP +30 Shield", {0, 1, 0.5, 1})
  end

  if box.contents.rareItem then
    local player = require("src.entities.player")
    player.addToInventory("alien_tech", box.contents.rareItem.quantity)
    M.showNotification("+Alien Technology Fragment", {1, 0.8, 0, 1})
  end

  -- Create particles for opening effect
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

  ctx.camera.shake = math.max(ctx.camera.shake, 0.2)
end

function M.draw()
  for _, box in ipairs(ctx.lootBoxes) do
    love.graphics.push()
    love.graphics.translate(box.x, box.y)
    love.graphics.rotate(ctx.state.t * (box.spin or 1))

    -- Draw loot box as a metallic container
    love.graphics.setColor(0.6, 0.6, 0.7, 1)  -- Metallic gray
    love.graphics.rectangle("fill", -10, -10, 20, 20, 2, 2)

    -- Container details
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("fill", -8, -8, 16, 16, 1, 1)

    -- Glow effect when can interact
    if box.canInteract then
      love.graphics.setColor(0.2, 0.8, 1, 0.5 + 0.3 * math.sin(ctx.state.t * 6))
      love.graphics.rectangle("fill", -12, -12, 24, 24, 3, 3)
    end

    -- Interaction prompt
    if box.canInteract then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.printf("Press E to loot", box.x - 50, box.y - 30, 100, "center")
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
