local M = {}

function M.start(panel, mx, my)
  panel.drag = {ox = mx - (panel.x or 0), oy = my - (panel.y or 0)}
end

function M.update(panel, wndW, wndH)
  if not panel.drag then return end
  local mx, my = love.mouse.getPosition()
  panel.x = mx - panel.drag.ox
  panel.y = my - panel.drag.oy
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()
  panel.x = math.max(0, math.min(panel.x, W - wndW))
  panel.y = math.max(0, math.min(panel.y, H - wndH))
end

function M.stop(panel)
  panel.drag = nil
end

return M

