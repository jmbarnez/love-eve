local state = require("src.core.state")
local theme = require("src.ui.theme")
local window = require("src.ui.components.window")
local drag = require("src.ui.core.drag")

local Panel = {
  x = nil,
  y = nil,
  drag = nil,
}

function Panel.isOpen()
  local playerEntity = state.get("player")
  return playerEntity and playerEntity.docked and state.get("station") ~= nil
end

function Panel.update(dt)
  if not Panel.isOpen() then return end
  drag.update(Panel, 300, 200)
end

function Panel.draw()
  if not Panel.isOpen() then return end

  local station = require("src.entities.space_station")
  local totalBounty = station.getTotalBounty()

  if totalBounty <= 0 then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  local WND_W, WND_H = 300, 200
  if not Panel.x or not Panel.y then
    Panel.x = W - WND_W - 20
    Panel.y = H - WND_H - 20
  end
  local x, y = Panel.x, Panel.y

  local closeRect = window.draw(x, y, WND_W, WND_H, "BOUNTY OFFICE")

  local mainX, mainY = x + 1, y + window.TITLE_H
  local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H

  -- Bounty information
  love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
  love.graphics.printf("Available Bounties", mainX + 10, mainY + 10, mainW - 20, "center")

  love.graphics.setColor(0.9, 0.8, 0.3, 1)
  local credit = require("src.content.credit")
  credit.draw(mainX + mainW/2 - 40, mainY + 40, 16)
  love.graphics.printf(string.format("Total: %s Credits", totalBounty >= 1000000 and string.format("%.1fM", totalBounty/1000000) or string.format("%.2f", totalBounty)),
                      mainX + 10, mainY + 45, mainW - 20, "center")

  -- Claim button
  local btnW, btnH = 120, 40
  local bx = mainX + (mainW - btnW) / 2
  local by = mainY + mainH - btnH - 20

  -- Button background
  love.graphics.setColor(0.04, 0.5, 0.2, 1)
  love.graphics.rectangle("fill", bx, by, btnW, btnH, 6)

  -- Button text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("CLAIM BOUNTY", bx, by + 12, btnW, "center")

  -- Button border
  love.graphics.setColor(0.2, 0.8, 0.3, 1)
  love.graphics.rectangle("line", bx, by, btnW, btnH, 6)
end

function Panel.mousepressed(x, y, button)
  if button ~= 1 or not Panel.isOpen() then return false end

  local WND_W, WND_H = 300, 200
  local wx, wy = Panel.x or 0, Panel.y or 0

  if window.isInTitle(x, y, wx, wy, WND_W) then
    if window.isInRect(x, y, window.closeRect(wx, wy, WND_W)) then
      -- Close the bounty panel (just hide it, player can reopen by docking)
      return true
    end
    drag.start(Panel, x, y)
    return true
  end

  -- Check claim button
  local station = require("src.entities.space_station")
  local totalBounty = station.getTotalBounty()

  if totalBounty > 0 then
    local mainX, mainY = wx + 1, wy + window.TITLE_H
    local mainW, mainH = WND_W - 1, WND_H - window.TITLE_H
    local btnW, btnH = 120, 40
    local bx = mainX + (mainW - btnW) / 2
    local by = mainY + mainH - btnH - 20

    if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
      station.claimBounties()
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
