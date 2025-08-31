
local ctx     = require("src.core.state")
local util    = require("src.core.util")
local enemies = require("src.entities.enemy")
local projectiles = require("src.systems.projectiles")
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
  local x, y = ctx.station.x, ctx.station.y
  local t = ctx.state.t
  
  -- Main station structure (much larger)
  local mainRadius = 280
  local coreRadius = 120
  
  -- Docking bay glow (larger radius for massive station)
  love.graphics.setColor(0.3, 0.8, 1.0, 0.08)
  love.graphics.circle("fill", x, y, 320)
  
  -- Outer defensive ring (rotating slowly)
  love.graphics.setColor(0.6, 0.9, 1.0, 0.8)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(t * 0.05)
  for i = 1, 12 do
    love.graphics.push()
    love.graphics.rotate(i * math.pi / 6)
    love.graphics.translate(mainRadius, 0)
    love.graphics.rectangle("line", -8, -24, 16, 48)
    love.graphics.rectangle("line", -4, -16, 8, 32)
    love.graphics.pop()
  end
  love.graphics.pop()
  
  -- Main station hull (octagonal core)
  love.graphics.setColor(0.8, 1.0, 1.0, 1.0)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(t * 0.08)
  
  -- Central octagon
  local points = {}
  for i = 1, 8 do
    local angle = i * math.pi / 4
    table.insert(points, math.cos(angle) * coreRadius)
    table.insert(points, math.sin(angle) * coreRadius)
  end
  love.graphics.polygon("line", points)
  
  -- Inner core details
  love.graphics.circle("line", 0, 0, 60)
  love.graphics.circle("line", 0, 0, 40)
  
  -- Rotating inner rings
  for ring = 1, 3 do
    love.graphics.push()
    love.graphics.rotate(t * (0.15 + ring * 0.05) * (ring % 2 == 0 and -1 or 1))
    local ringRadius = 20 + ring * 15
    for i = 1, 6 do
      love.graphics.push()
      love.graphics.rotate(i * math.pi / 3)
      love.graphics.line(0, ringRadius - 5, 0, ringRadius + 5)
      love.graphics.pop()
    end
    love.graphics.pop()
  end
  love.graphics.pop()
  
  -- Docking arms (4 major arms extending outward)
  love.graphics.setColor(0.7, 0.95, 1.0, 0.9)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(t * 0.03)
  
  for i = 1, 4 do
    love.graphics.push()
    love.graphics.rotate(i * math.pi / 2)
    
    -- Main arm structure
    love.graphics.rectangle("line", 0, -12, 180, 24)
    love.graphics.rectangle("line", 160, -20, 40, 40)
    
    -- Arm details
    for j = 1, 3 do
      local armX = j * 50
      love.graphics.line(armX, -8, armX, 8)
    end
    
    -- Docking port at end
    love.graphics.circle("line", 200, 0, 16)
    love.graphics.circle("line", 200, 0, 8)
    
    love.graphics.pop()
  end
  love.graphics.pop()
  
  -- Communication arrays and sensors
  love.graphics.setColor(0.5, 0.8, 1.0, 0.7)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(t * -0.02)
  
  for i = 1, 8 do
    love.graphics.push()
    love.graphics.rotate(i * math.pi / 4)
    love.graphics.translate(150, 0)
    love.graphics.line(0, -30, 0, 30)
    love.graphics.line(-5, -25, 5, -25)
    love.graphics.line(-5, 25, 5, 25)
    love.graphics.pop()
  end
  love.graphics.pop()
  
  -- Pulsing energy core
  love.graphics.setColor(0.2, 0.9, 1.0, 0.6 + 0.4 * math.sin(t * 3))
  love.graphics.circle("fill", x, y, 25)
  love.graphics.setColor(1.0, 1.0, 1.0, 0.8 + 0.2 * math.sin(t * 3))
  love.graphics.circle("fill", x, y, 12)
  
  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
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

  -- projectiles top so they render above ships
  projectiles.draw()

  -- particles
  for _,p in ipairs(ctx.particles) do
    love.graphics.setColor(1,1,1, math.max(0, math.min(1, p.life)))
    love.graphics.points(p.x, p.y)
  end
  love.graphics.setColor(1,1,1,1)

  -- movement waypoint
  if ctx.player.moveTarget and not ctx.player.docked then
    love.graphics.setColor(0.4, 1, 0.9, 0.8)
    local tx, ty = ctx.player.moveTarget.x, ctx.player.moveTarget.y
    
    -- Main waypoint circle
    love.graphics.circle("line", tx, ty, 12)
    
    -- Animated rings
    for i = 1, 2 do
      local radius = 15 + i * 8 + math.sin(ctx.state.t * 3 + i) * 3
      local alpha = 0.6 - i * 0.2
      love.graphics.setColor(0.4, 1, 0.9, alpha)
      love.graphics.arc("line", tx, ty, radius, 0, math.pi * 2)
    end
    
  end

  -- target indicator
  if ctx.player.autoAttackTarget and ctx.player.autoAttackTarget.hp > 0 then
    local target = ctx.player.autoAttackTarget
    local x, y = target.x, target.y
    local r = target.radius + 10
    local t = ctx.state.t

    love.graphics.setColor(1, 0.2, 0.2, 0.9)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(t * 2)
    love.graphics.line(-r, -r, r, r)
    love.graphics.line(-r, r, r, -r)
    love.graphics.pop()
  end
end

return M
