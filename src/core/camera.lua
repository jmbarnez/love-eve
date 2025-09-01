
local ctx = require("src.core.state")
local M = {}

function M.update(dt)
  local G = ctx.get("gameState").G
  local p = ctx.get("player")
  local camera = ctx.get("camera")
  camera.x = (camera.x + (p.x - camera.x) * math.min(1, dt*G.CAMERA_SMOOTH))
  camera.y = (camera.y + (p.y - camera.y) * math.min(1, dt*G.CAMERA_SMOOTH))
  if camera.shake>0 then camera.shake = math.max(0, camera.shake - dt) end
end

function M.push()
  local lg = love.graphics
  lg.push()
  local camera = ctx.get("camera")
  local gameState = ctx.get("gameState")
  local sx = love.math.random() * (camera.shake*2) - camera.shake
  local sy = love.math.random() * (camera.shake*2) - camera.shake
  lg.translate(lg.getWidth()/2, lg.getHeight()/2)
  lg.scale(gameState.zoom, gameState.zoom)
  lg.translate(-camera.x + sx, -camera.y + sy)
end

function M.pop() love.graphics.pop() end
return M
