local ctx = require("src.core.state")
local theme = require("src.ui.theme")
local bars = require("src.ui.components.bars")
local modules = require("src.systems.modules")
local item_icon = require("src.ui.components.item_icon")
local tooltip = require("src.ui.components.tooltip")

local M = {}

function M.draw()
  local p = ctx.get("player")
  if not p then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

  -- Bottom-left cluster (three rings)
  local marginX, marginY = 90, 90
  local cx = marginX
  local cy = H - marginY

  local capR = 26
  local hullR = capR + 9
  local shieldR = hullR + 6

  -- Energy (capacitor) center ring
  bars.ringProgress(cx, cy, capR, p.energy or 0, p.maxEnergy or 1, theme.energy, nil, { thickness = 5 })

  -- Hull and Shield outer rings
  bars.ringProgress(cx, cy, shieldR, p.shield or 0, p.maxShield or 1, theme.primary, nil, { thickness = 3 })
  bars.ringProgress(cx, cy, hullR,   p.hp or 0,     p.maxHP or 1,     theme.warning, nil, { thickness = 3 })

  -- Central module hotbar
  local active_modules = modules.get_modules()
  if #active_modules > 0 then
    local BAR_WIDTH = 400
    local BAR_HEIGHT = 60
    local ICON_SIZE = 48
    local bar_x = (W - BAR_WIDTH) / 2
    local bar_y = H - BAR_HEIGHT - 20

    -- Draw a semi-transparent background for the bar
    love.graphics.setColor(0.1, 0.1, 0.1, 0.7)
    love.graphics.rectangle("fill", bar_x, bar_y, BAR_WIDTH, BAR_HEIGHT, 5)

    for i, module in ipairs(active_modules) do
        local icon_x = bar_x + (i - 1) * (ICON_SIZE + 10) + 10
        local icon_y = bar_y + (BAR_HEIGHT - ICON_SIZE) / 2

        -- Draw the item icon
        item_icon.draw(module.id, icon_x, icon_y, ICON_SIZE)

        -- Check for hover and draw tooltip
        local mx, my = love.mouse.getPosition()
        if mx > icon_x and mx < icon_x + ICON_SIZE and my > icon_y and my < icon_y + ICON_SIZE then
            tooltip.draw_text(module.def.name, module.def.description)
        end

        -- Draw cooldown/duration overlay
        if module.state == "cooldown" then
            local cooldown_percent = module.cooldown / (module.def.cooldown or 5)
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.rectangle("fill", icon_x, icon_y + ICON_SIZE * (1 - cooldown_percent), ICON_SIZE, ICON_SIZE * cooldown_percent)
        elseif module.state == "active" then
            love.graphics.setColor(0, 1, 0, 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("fill", icon_x, icon_y, ICON_SIZE, ICON_SIZE)
        end

        -- Draw the key binding
        love.graphics.setColor(theme.text)
        local key = ({"Q", "W", "E", "R"})[i]
        if key then
          love.graphics.printf(key, icon_x, icon_y + ICON_SIZE - 12, ICON_SIZE, "center")
        end
    end
  end


  -- Top-right minimap
  local MAP_SIZE = 150
  local MAP_MARGIN_X, MAP_MARGIN_Y = 20, 20
  local mapX = W - MAP_SIZE - MAP_MARGIN_X
  local mapY = MAP_MARGIN_Y
  local centerX = mapX + MAP_SIZE / 2
  local centerY = mapY + MAP_SIZE / 2

  -- Minimap background
  love.graphics.setColor(0.1, 0.1, 0.12, 0.8)
  love.graphics.rectangle("fill", mapX, mapY, MAP_SIZE, MAP_SIZE, 4)
  love.graphics.setColor(0.3, 0.3, 0.4, 0.7)
  love.graphics.rectangle("line", mapX, mapY, MAP_SIZE, MAP_SIZE, 4)

  -- Minimap bounds circle (representing world limit)
  local maxDist = 2000 -- Adjust based on world size
  love.graphics.setColor(0.4, 0.4, 0.5, 0.5)
  love.graphics.circle("line", centerX, centerY, MAP_SIZE / 2 * 0.8)

  -- Draw enemies on minimap
  local enemies = ctx.get("enemies") or {}
  love.graphics.setColor(1, 0.3, 0.3, 0.8) -- Red for enemies
  for _, enemy in ipairs(enemies) do
    local relX = (enemy.x - p.x) / maxDist
    local relY = (enemy.y - p.y) / maxDist
    local mapPtX = centerX + relX * (MAP_SIZE / 2 * 0.8)
    local mapPtY = centerY + relY * (MAP_SIZE / 2 * 0.8)
    if relX >= -1 and relX <= 1 and relY >= -1 and relY <= 1 then
      love.graphics.points(mapPtX, mapPtY)
    end
  end

  -- Draw space station
  local station = ctx.get("station")
  if station then
    love.graphics.setColor(0.3, 0.8, 1, 0.8) -- Blue for station
    local relX = (station.x - p.x) / maxDist
    local relY = (station.y - p.y) / maxDist
    local mapPtX = centerX + relX * (MAP_SIZE / 2 * 0.8)
    local mapPtY = centerY + relY * (MAP_SIZE / 2 * 0.8)
    if relX >= -1 and relX <= 1 and relY >= -1 and relY <= 1 then
      love.graphics.points(mapPtX, mapPtY)
    end
  end

  -- Draw loot items (yellow circles)
  local loots = ctx.get("loots") or {}
  love.graphics.setColor(1.0, 1.0, 0.0, 0.8) -- Yellow for loot
  for _, loot in ipairs(loots) do
    local relX = (loot.x - p.x) / maxDist
    local relY = (loot.y - p.y) / maxDist
    local mapPtX = centerX + relX * (MAP_SIZE / 2 * 0.8)
    local mapPtY = centerY + relY * (MAP_SIZE / 2 * 0.8)
    if relX >= -1 and relX <= 1 and relY >= -1 and relY <= 1 then
      love.graphics.circle("fill", mapPtX, mapPtY, 1.5)
    end
  end

  -- Draw wreckage (gray)
  local wreckage = ctx.get("wreckage") or {}
  love.graphics.setColor(0.5, 0.5, 0.5, 0.8) -- Gray for wreckage
  for _, wreck in ipairs(wreckage) do
    local relX = (wreck.x - p.x) / maxDist
    local relY = (wreck.y - p.y) / maxDist
    local mapPtX = centerX + relX * (MAP_SIZE / 2 * 0.8)
    local mapPtY = centerY + relY * (MAP_SIZE / 2 * 0.8)
    if relX >= -1 and relX <= 1 and relY >= -1 and relY <= 1 then
      love.graphics.points(mapPtX, mapPtY)
    end
  end

  -- Draw player at center (green)
  love.graphics.setColor(0.3, 1, 0.3, 1)
  love.graphics.points(centerX, centerY)

  -- FPS counter underneath minimap
  local fpsX = mapX
  local fpsY = mapY + MAP_SIZE + 10
  love.graphics.setColor(theme.text)
  love.graphics.printf("FPS: " .. love.timer.getFPS(), fpsX, fpsY, MAP_SIZE, "center")

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

return M