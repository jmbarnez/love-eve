
local ctx     = require("src.core.ctx")
local util    = require("src.core.util")
local enemies = require("src.entities.enemy")
local bullets = require("src.entities.bullet")
local loot    = require("src.entities.loot")
local player  = require("src.entities.player")

local M = {}

local function genStars()
  love.math.setRandomSeed(1337)
  local W = ctx.G.WORLD_SIZE
  ctx.starsBG = {}
  for i=1,ctx.G.STAR_COUNT_BG do
    ctx.starsBG[i] = {x=util.randf(-W,W), y=util.randf(-W,W), s=util.randf(0.5,1.6)}
  end
  ctx.starsFG = {}
  for i=1,ctx.G.STAR_COUNT_FG do
    ctx.starsFG[i] = {x=util.randf(-W,W), y=util.randf(-W,W), s=util.randf(1.2,2.4)}
  end
end

local function drawStation()
  local s = 56
  love.graphics.setColor(0.75,1.0,0.9,0.15)
  love.graphics.circle("fill", ctx.station.x, ctx.station.y, 140)
  love.graphics.setColor(0.8,1,1,1)
  love.graphics.push(); love.graphics.translate(ctx.station.x, ctx.station.y); love.graphics.rotate(ctx.state.t*0.1)
  for i=1,6 do
    love.graphics.push(); love.graphics.rotate(i*math.pi/3)
    love.graphics.polygon("line", s,0, s*0.5, s*0.35, 0,s, -s*0.5, s*0.35, -s,0, -s*0.5, -s*0.35, 0,-s, s*0.5,-s*0.35)
    love.graphics.pop()
  end
  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)
end

function M.init()
  genStars()
  ctx.station = {x=0,y=0}
end

function M.draw()
  -- stars
  love.graphics.setColor(1,1,1,0.5); for _,s in ipairs(ctx.starsBG) do love.graphics.points(s.x, s.y) end
  love.graphics.setColor(1,1,1,0.85); for _,s in ipairs(ctx.starsFG) do love.graphics.points(s.x, s.y) end

  -- bounds
  love.graphics.setColor(1,1,1,0.07)
  love.graphics.rectangle("line", -ctx.G.WORLD_SIZE, -ctx.G.WORLD_SIZE, ctx.G.WORLD_SIZE*2, ctx.G.WORLD_SIZE*2)

  -- station
  drawStation()

  loot.draw()
  enemies.draw()
  player.draw()

  -- bullets top so they render above ships
  bullets.draw()

  -- particles
  for _,p in ipairs(ctx.particles) do
    love.graphics.setColor(1,1,1, math.max(0, math.min(1, p.life)))
    love.graphics.points(p.x, p.y)
  end
  love.graphics.setColor(1,1,1,1)

  -- waypoint
  if ctx.player.autopilot and not ctx.player.docked then
    love.graphics.setColor(0.4,1,0.9,0.6)
    local tx,ty = ctx.player.autopilot.tx, ctx.player.autopilot.ty
    love.graphics.circle("line", tx,ty, 18)
    for i=1,3 do love.graphics.arc("line", tx,ty, 20+i*4, 0, ctx.state.t*2 + i*0.8) end
    love.graphics.setColor(1,1,1,1)
  end
end

return M
