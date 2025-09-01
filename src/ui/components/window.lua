local theme = require("src.ui.theme")
local settings = require("src.core.settings")

local ui_scale = settings.build().UI_SCALE

local Window = {
  TITLE_H = 30 * ui_scale,
  ui_scale = ui_scale
}

function Window.draw(x, y, w, h, title)
  love.graphics.setColor(0.02, 0.05, 0.08, 0.98)
  love.graphics.rectangle("fill", x, y, w, h, 4 * ui_scale)

  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
  love.graphics.setLineWidth(1 * ui_scale)
  love.graphics.rectangle("line", x, y, w, h, 4 * ui_scale)

  love.graphics.setColor(0.08, 0.15, 0.22, 1)
  love.graphics.rectangle("fill", x, y, w, Window.TITLE_H, 4 * ui_scale)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
  love.graphics.line(x, y + Window.TITLE_H, x + w, y + Window.TITLE_H)

  if title then
    love.graphics.setColor(theme.text)
    love.graphics.printf(title, x + (10 * ui_scale), y + (8 * ui_scale), w - (20 * ui_scale), "left")
  end

  -- Close button
  local cr = Window.closeRect(x, y, w)
  love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
  love.graphics.rectangle("fill", cr.x, cr.y, cr.w, cr.h, 2 * ui_scale)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("×", cr.x, cr.y, cr.w, "center")

  return cr
end

function Window.closeRect(x, y, w)
  return {x = x + w - (25 * ui_scale), y = y + (5 * ui_scale), w = 20 * ui_scale, h = 20 * ui_scale}
end

function Window.isInRect(mx, my, r)
  return mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h
end

function Window.isInTitle(mx, my, x, y, w)
  return mx >= x and mx <= x + w and my >= y and my <= y + Window.TITLE_H
end

return Window
