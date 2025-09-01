local items = require("src.content.items.registry")
local theme = require("src.ui.theme")

local M = {}

function M.draw(itemType, quantity, x, y)
  local itemDef = items.get(itemType)
  local name = (itemDef and itemDef.name) or itemType
  local text = name .. "\nQuantity: " .. tostring(quantity)
  if itemDef and itemDef.description then
    text = text .. "\n" .. itemDef.description
  end
  if itemDef and itemDef.value then
    text = text .. "\nValue: " .. itemDef.value .. " credits each"
  end

  local font = love.graphics.getFont()
  local lines = {}
  for line in text:gmatch("[^\n]+") do table.insert(lines, line) end

  local maxW = 0
  for _, line in ipairs(lines) do maxW = math.max(maxW, font:getWidth(line)) end
  local h = #lines * font:getHeight() + 10
  local w = maxW + 20

  love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
  love.graphics.rectangle("fill", x, y, w, h, 4)

  love.graphics.setColor(theme.border)
  love.graphics.rectangle("line", x, y, w, h, 4)

  love.graphics.setColor(1, 1, 1, 1)
  for i, line in ipairs(lines) do
    love.graphics.printf(line, x + 10, y + 5 + (i - 1) * font:getHeight(), w - 20, "left")
  end
end

function M.draw_text(title, text)
    local full_text = title .. "\n" .. text
    local font = love.graphics.getFont()
    local lines = {}
    for line in full_text:gmatch("[^\n]+") do table.insert(lines, line) end

    local maxW = 0
    for _, line in ipairs(lines) do maxW = math.max(maxW, font:getWidth(line)) end
    local h = #lines * font:getHeight() + 10
    local w = maxW + 20

    local x, y = love.mouse.getPosition()
    x = x + 15
    y = y + 15

    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 4)

    love.graphics.setColor(theme.border)
    love.graphics.rectangle("line", x, y, w, h, 4)

    love.graphics.setColor(1, 1, 1, 1)
    for i, line in ipairs(lines) do
        love.graphics.printf(line, x + 10, y + 5 + (i - 1) * font:getHeight(), w - 20, "left")
    end
end

return M
