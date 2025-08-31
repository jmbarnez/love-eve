
local state = require("src.core.state")
local util = require("src.core.util")
local enemies = require("src.entities.enemy")
local projectiles = require("src.systems.projectiles")
local loot = require("src.entities.loot")
local player = require("src.entities.player")
local config = require("src.core.config")

local M = {}

-- Static star data (generated once on startup)
local staticStars = {}
local auroraBands = {}

local function genStars()
  love.math.setRandomSeed(os.time()) -- Use current time for randomness
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

  staticStars = {} -- Clear and regenerate

  -- Background stars (dimmest, smallest)
  staticStars.background = {}
  for i = 1, 32 do
    staticStars.background[i] = {
      x = love.math.random(0, W),
      y = love.math.random(0, H),
      size = love.math.random(0.5, 1.2),
      alpha = 0.2 + love.math.random() * 0.4
    }
  end

  -- Foreground stars (medium brightness)
  staticStars.foreground = {}
  for i = 1, 18 do
    staticStars.foreground[i] = {
      x = love.math.random(0, W),
      y = love.math.random(0, H),
      size = love.math.random(1.0, 2.2),
      alpha = 0.4 + love.math.random() * 0.4
    }
  end

  -- Special bright stars (most visible)
  staticStars.bright = {}
  for i = 1, 8 do
    staticStars.bright[i] = {
      x = love.math.random(0, W),
      y = love.math.random(0, H),
      size = love.math.random(1.5, 3.0),
      alpha = 0.7 + love.math.random() * 0.3
    }
  end
end

local function genAurora()
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

  auroraBands = {} -- Clear and regenerate

  -- Generate 2-5 random aurora bands with varied properties
  local numBands = love.math.random(2, 5)

  for i = 1, numBands do
    -- Random aurora types
    local auroraType = love.math.random()
    local colorSet

    if auroraType < 0.3 then
      -- Green aurora
      colorSet = {
        color1 = {0.1 + love.math.random() * 0.1, 0.7 + love.math.random() * 0.2, 0.1 + love.math.random() * 0.2},
        color2 = {0.1 + love.math.random() * 0.1, 0.4 + love.math.random() * 0.3, 0.3 + love.math.random() * 0.2}
      }
    elseif auroraType < 0.6 then
      -- Blue-purple aurora
      colorSet = {
        color1 = {0.1 + love.math.random() * 0.1, 0.2 + love.math.random() * 0.2, 0.8 + love.math.random() * 0.2},
        color2 = {0.2 + love.math.random() * 0.1, 0.5 + love.math.random() * 0.3, 0.8 + love.math.random() * 0.2}
      }
    else
      -- Mixed aurora (greens to blues)
      colorSet = {
        color1 = {0.1 + love.math.random() * 0.1, love.math.random(0.6, 0.9), 0.2 + love.math.random() * 0.2},
        color2 = {0.05 + love.math.random() * 0.1, 0.3 + love.math.random() * 0.3, 0.7 + love.math.random() * 0.3}
      }
    end

    auroraBands[i] = {
      -- Base properties with more variation
      baseY = H * (0.15 + love.math.random() * 0.7), -- Completely random vertical positioning
      amplitude = love.math.random(15, 60), -- More varied wave amplitude
      frequency = 0.002 + love.math.random() * 0.004, -- More varied wave frequency
      phase = love.math.random() * math.pi * 2, -- Random phase
      speed = (0.0003 + love.math.random() * 0.001) * (love.math.random() < 0.5 and 1 or -1), -- Some move left, some right
      length = W * (0.4 + love.math.random() * 0.6), -- More varied lengths
      segments = 25 + love.math.random(15, 35), -- Varied curve smoothness
      waveCount = love.math.random(2, 5), -- Different wave patterns
      offset = love.math.random() * math.pi * 2, -- Different wave offsets
      color1 = colorSet.color1,
      color2 = colorSet.color2,
      alphaBase = 0.02 + love.math.random() * 0.06, -- Variable base opacity
    }
  end
end

local function drawAurora(t)
  if #auroraBands == 0 then return end

  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

  for _, band in ipairs(auroraBands) do
    -- Create a wavy curve
    local points = {}
    local segmentWidth = band.length / (band.segments * 2) -- Double for return path

    local startX = (W - band.length) * 0.5

    -- Draw the ribbon effect by layering multiple paths with slight offsets
    for offset = 0, 8, 2 do
      points = {}

      for i = 0, band.segments do
        local x = startX + (i * segmentWidth * 2)
        local wave = math.sin((x + t * band.speed) * band.frequency + band.phase + offset * 0.001)
        local y = band.baseY + (wave * band.amplitude) - offset * 2

        table.insert(points, x)
        table.insert(points, y)
      end

      -- Add return path to close the ribbon
      for i = band.segments, 0, -1 do
        local x = startX + (i * segmentWidth * 2)
        local wave = math.sin((x + t * band.speed) * band.frequency + band.phase + (offset + 2) * 0.001)
        local y = band.baseY + (wave * band.amplitude) - (offset + 2) * 2

        table.insert(points, x)
        table.insert(points, y)
      end

      -- Interpolate colors for aurora effect
      local colorMix = (math.sin(t * 0.001 + band.phase + offset * 0.01) + 1) * 0.5
      local r = band.color1[1] * (1 - colorMix) + band.color2[1] * colorMix
      local g = band.color1[2] * (1 - colorMix) + band.color2[2] * colorMix
      local b = band.color1[3] * (1 - colorMix) + band.color2[3] * colorMix
      local alpha = band.alphaBase * (0.8 + 0.4 * colorMix) * (0.7 + offset * 0.04)

      love.graphics.setColor(r, g, b, alpha)
      love.graphics.polygon("fill", points)
    end

    love.graphics.setColor(1, 1, 1, 1)
  end
end

local function drawStation()
  local station = state.get("station")
  local gameState = state.get("gameState")
  local worldConfig = config.world
  local x, y = station.x, station.y
  local t = gameState.t
  
  -- Main station structure (much larger)
  local mainRadius = worldConfig.stationRadius
  local coreRadius = worldConfig.coreRadius
  
  -- Docking bay glow (larger radius for massive station)
  love.graphics.setColor(0.3, 0.8, 1.0, 0.08)
  love.graphics.circle("fill", x, y, worldConfig.dockingRadius)
  
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
  genAurora() -- Generate aurora effects
  local station = {x=0,y=0}
  state.set("station", station)
end

function M.draw()
  local gameConfig = config.game
  local starsBG = state.get("starsBG")
  local starsFG = state.get("starsFG")
  local particles = state.get("particles")
  local gameState = state.get("gameState")
  local playerEntity = state.get("player")
  local camera = state.get("camera")
  local W, H = love.graphics.getWidth(), love.graphics.getHeight()

  -- Draw stars BEFORE camera transform (off-screen buffer)
  love.graphics.push() -- Temporarily draw in screen coordinates
  love.graphics.origin() -- Reset to screen origin

  -- Draw aurora effects behind stars (very subtle atmospheric effect)
  drawAurora(gameState.t)

  -- Draw static starfield (generated once at startup)
  if staticStars.background then
    for _, star in ipairs(staticStars.background) do
      love.graphics.setColor(1, 1, 1, star.alpha)
      love.graphics.circle("fill", star.x, star.y, star.size)
    end
  end

  if staticStars.foreground then
    for _, star in ipairs(staticStars.foreground) do
      love.graphics.setColor(1, 1, 1, star.alpha)
      love.graphics.circle("fill", star.x, star.y, star.size)
    end
  end

  if staticStars.bright then
    for _, star in ipairs(staticStars.bright) do
      love.graphics.setColor(1, 1, 1, star.alpha)
      love.graphics.circle("fill", star.x, star.y, star.size)
    end
  end

  love.graphics.pop() -- Restore graphics state for world rendering

  -- bounds
  love.graphics.setColor(1,1,1,0.07)
  love.graphics.rectangle("line", -gameConfig.WORLD_SIZE, -gameConfig.WORLD_SIZE, gameConfig.WORLD_SIZE*2, gameConfig.WORLD_SIZE*2)

  -- station
  drawStation()

  loot.draw()
  enemies.draw()
  player.draw()

  -- projectiles top so they render above ships
  projectiles.draw()

  -- particles (drawn over everything)
  love.graphics.push()
  love.graphics.origin()
  for _,p in ipairs(particles) do
    love.graphics.setColor(1,1,1, math.max(0, math.min(1, p.life)))
    love.graphics.points(p.x - camera.x + W/2, p.y - camera.y + H/2)
  end
  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)

  -- movement waypoint (drawn in world space)
  if playerEntity.moveTarget and not playerEntity.docked then
    love.graphics.setColor(0.4, 1, 0.9, 0.8)
    local tx, ty = playerEntity.moveTarget.x, playerEntity.moveTarget.y

    -- Main waypoint circle
    love.graphics.circle("line", tx, ty, config.world.waypointRadius)

    -- Animated rings
    for i = 1, 2 do
      local radius = 15 + i * 8 + math.sin(gameState.t * 3 + i) * 3
      local alpha = 0.6 - i * 0.2
      love.graphics.setColor(0.4, 1, 0.9, alpha)
      love.graphics.arc("line", tx, ty, radius, 0, math.pi * 2)
    end

  end

  -- target indicator removed - spinning crosshairs disabled
end

return M
