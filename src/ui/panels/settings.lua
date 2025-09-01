local state = require("src.core.state")
local theme = require("src.ui.theme")
local window = require("src.ui.components.window")
local drag = require("src.ui.core.drag")

local Panel = {
  open = false,
  x = nil,
  y = nil,
  drag = nil,
}

function Panel.toggle()
  Panel.open = not Panel.open
  local gameState = state.get("gameState")
  gameState.paused = Panel.open -- Pause game when settings are open
end

function Panel.isOpen()
  return Panel.open
end

function Panel.update(dt)
  if not Panel.open then return end
  local ui_scale = window.ui_scale
  local btnW = 200 * ui_scale
  local WND_W, WND_H = btnW + (40 * ui_scale), 400 * ui_scale
  drag.update(Panel, WND_W, WND_H)
end

function Panel.draw()
  if not Panel.open then return end
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local ui_scale = window.ui_scale
  local btnW = 200 * ui_scale
  local WND_W, WND_H = btnW + (40 * ui_scale), 400 * ui_scale -- Panel width based on button + padding
  if not Panel.x or not Panel.y then
    Panel.x = (W - WND_W) / 2
    Panel.y = (H - WND_H) / 2
  end

  local x, y = Panel.x, Panel.y
  local closeRect = window.draw(x, y, WND_W, WND_H, "SETTINGS")

  -- Resume Game Button
  local btnW, btnH = 200 * ui_scale, 40 * ui_scale
  local btnX, btnY = x + (WND_W - btnW) / 2, y + window.TITLE_H + (50 * ui_scale)

  love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.8)
  love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4 * ui_scale)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Resume Game", btnX, btnY + (btnH - love.graphics.getFont():getHeight()) / 2, btnW, "center")
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.open then return false end
  local ui_scale = window.ui_scale
  local btnW = 200 * ui_scale
  local WND_W, WND_H = btnW + (40 * ui_scale), 400 * ui_scale
  local wx, wy = Panel.x or 0, Panel.y or 0

  -- Check for close button click
  if window.isInTitle(x, y, wx, wy, WND_W) then
    if window.isInRect(x, y, window.closeRect(wx, wy, WND_W)) then
      Panel.toggle() -- Close panel and unpause
      return true
    end
    drag.start(Panel, x, y)
    return true
  end

  -- Check for "Resume Game" button click
  local btnW, btnH = 200 * ui_scale, 40 * ui_scale
  local btnX, btnY = wx + (WND_W - btnW) / 2, wy + window.TITLE_H + (50 * ui_scale)
  if x >= btnX and x <= btnX + btnW and y >= btnY and y <= btnY + btnH then
    Panel.toggle() -- Close panel and unpause
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

function Panel.keypressed(key)
  if key == "escape" then
    Panel.toggle() -- Close panel and unpause
    return true
  end
  return false
end

return Panel
