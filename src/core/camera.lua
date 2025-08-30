
local ctx = require("src.core.ctx")
local M = {}

function M.update(dt)
  local G = ctx.G
  local p = ctx.player
  ctx.camera.x = (ctx.camera.x + (p.x - ctx.camera.x) * math.min(1, dt*G.CAMERA_SMOOTH))
  ctx.camera.y = (ctx.camera.y + (p.y - ctx.camera.y) * math.min(1, dt*G.CAMERA_SMOOTH))
  if ctx.camera.shake>0 then ctx.camera.shake = math.max(0, ctx.camera.shake - dt) end
end

function M.push()
  local lg = love.graphics
  lg.push()
  local sx = love.math.random() * (ctx.camera.shake*2) - ctx.camera.shake
  local sy = love.math.random() * (ctx.camera.shake*2) - ctx.camera.shake
  lg.translate(lg.getWidth()/2, lg.getHeight()/2)
  lg.scale(ctx.G.ZOOM, ctx.G.ZOOM)
  lg.translate(-ctx.camera.x + sx, -ctx.camera.y + sy)
end

function M.pop() love.graphics.pop() end
return M
