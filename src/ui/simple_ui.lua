-- Minimal Sci-Fi HUD System (modular orchestrator)
local hud = require("src.ui.overlay.hud")
local panel_inventory = require("src.ui.panels.inventory")
local panel_container = require("src.ui.panels.container")

local SimpleUI = {}

function SimpleUI.init()
  SimpleUI.enabled = true
end

function SimpleUI.update(dt)
  if not SimpleUI.enabled then return end
  panel_inventory.update(dt)
  panel_container.update(dt)
end

function SimpleUI.draw()
  if not SimpleUI.enabled then return end
  love.graphics.push()
  love.graphics.origin()
  hud.draw()
  if panel_inventory.isOpen() then panel_inventory.draw() end
  if panel_container.isOpen() then panel_container.draw() end
  love.graphics.pop()
end

function SimpleUI.mousepressed(x, y, button)
  if button ~= 1 then return false end
  if panel_inventory.mousepressed(x, y, button) then return true end
  if panel_container.mousepressed(x, y, button) then return true end
  return false
end

function SimpleUI.mousereleased(x, y, button)
  if panel_inventory.mousereleased(x, y, button) then return true end
  if panel_container.mousereleased(x, y, button) then return true end
  return false
end

function SimpleUI.keypressed(key)
  if key == "tab" then panel_inventory.toggle(); return true end
  return false
end

return SimpleUI

