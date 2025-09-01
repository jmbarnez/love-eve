-- Minimal Sci-Fi HUD System (modular orchestrator)
local hud = require("src.ui.overlay.hud")
local panel_inventory = require("src.ui.panels.inventory")
local panel_equipment = require("src.ui.panels.equipment")
local panel_bounty = require("src.ui.panels.bounty")
local panel_settings = require("src.ui.panels.settings")

local SimpleUI = {}

function SimpleUI.init()
  SimpleUI.enabled = true
end

function SimpleUI.update(dt)
  if not SimpleUI.enabled then return end
  panel_inventory.update(dt)
  panel_equipment.update(dt)
  panel_bounty.update(dt)
  panel_settings.update(dt)

  -- Update notifications
  local notifications = require("src.core.state").get("notifications")
  if not notifications then return end
  for i = #notifications, 1, -1 do
    local n = notifications[i]
    n.timer = n.timer - dt
    if n.timer <= 0 then
      table.remove(notifications, i)
    end
  end
end

function SimpleUI.draw()
  if not SimpleUI.enabled then return end
  love.graphics.push()
  love.graphics.origin()
  hud.draw()
  if panel_inventory.isOpen() then panel_inventory.draw() end
  if panel_equipment.isOpen() then panel_equipment.draw() end
  if panel_bounty.isOpen() then panel_bounty.draw() end
  if panel_settings.isOpen() then panel_settings.draw() end

  -- Draw notifications
  local notifications = require("src.core.state").get("notifications")
  if not notifications then return end
  local camera = require("src.core.state").get("camera")
  local gameState = require("src.core.state").get("gameState")
  local lg = love.graphics

  for _, n in ipairs(notifications) do
    -- Convert world coordinates to screen coordinates
    local sx = (n.x - camera.x) * gameState.zoom + lg.getWidth() / 2
    local sy = (n.y - camera.y) * gameState.zoom + lg.getHeight() / 2

    -- Fade out effect
    local alpha = math.min(1, n.timer / 1.5) -- Fade out over 1.5 seconds
    love.graphics.setColor(1, 1, 1, alpha)

    -- Draw text centered
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(n.text)
    love.graphics.printf(n.text, sx - textWidth / 2, sy, textWidth, "center")
  end
  love.graphics.setColor(1, 1, 1, 1) -- Reset color

  love.graphics.pop()
end

function SimpleUI.mousepressed(x, y, button)
  if button ~= 1 then return false end
  if panel_inventory.mousepressed(x, y, button) then return true end
  if panel_equipment.mousepressed(x, y, button) then return true end
  if panel_bounty.mousepressed(x, y, button) then return true end
  if panel_settings.mousepressed(x, y, button) then return true end
  if hud.mousepressed(x, y, button) then return true end -- Add this line
  return false
end

function SimpleUI.mousereleased(x, y, button)
  if panel_inventory.mousereleased(x, y, button) then return true end
  if panel_equipment.mousereleased(x, y, button) then return true end
  if panel_bounty.mousereleased(x, y, button) then return true end
  if panel_settings.mousereleased(x, y, button) then return true end
  return false
end

function SimpleUI.keypressed(key)
  if key == "tab" then panel_inventory.toggle(); return true end
  if key == "g" then panel_equipment.toggle(); return true end
  if panel_settings.isOpen() then
    if panel_settings.keypressed(key) then return true end
  end
  return false
end

return SimpleUI
