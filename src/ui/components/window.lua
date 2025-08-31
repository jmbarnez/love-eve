local theme = require("src.ui.theme")

local Window = {
  TITLE_H = 30,
}

function Window.draw(x, y, w, h, title)
  love.graphics.setColor(0.02, 0.05, 0.08, 0.98)
  love.graphics.rectangle("fill", x, y, w, h, 4)

  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, h, 4)

  love.graphics.setColor(0.08, 0.15, 0.22, 1)
  love.graphics.rectangle("fill", x, y, w, Window.TITLE_H, 4)
  love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
  love.graphics.line(x, y + Window.TITLE_H, x + w, y + Window.TITLE_H)

  if title then
    love.graphics.setColor(theme.text)
    love.graphics.printf(title, x + 10, y + 8, w - 20, "left")
  end

  -- Close button
  local cr = Window.closeRect(x, y, w)
  love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
  love.graphics.rectangle("fill", cr.x, cr.y, cr.w, cr.h, 2)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("×", cr.x, cr.y, cr.w, "center")

  return cr
end

function Window.closeRect(x, y, w)
  return {x = x + w - 25, y = y + 5, w = 20, h = 20}
end

function Window.isInRect(mx, my, r)
  return mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h
end

function Window.isInTitle(mx, my, x, y, w)
  return mx >= x and mx <= x + w and my >= y and my <= y + Window.TITLE_H
end

return Window

