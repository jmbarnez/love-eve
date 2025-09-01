
local state = require("src.core.state")
local util = require("src.core.util")
local enemies = require("src.entities.enemy")
local projectiles = require("src.systems.projectiles")
local loot = require("src.entities.loot")
local player = require("src.entities.player")
local spaceStation = require("src.entities.space_station")
local config = require("src.core.config")

local M = {}

-- Static star data (generated once on startup)
local staticStars = {}

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
  -- Aurora generation removed
end

local function drawAurora(t)
  -- Aurora drawing removed
end

function M.init()
  genStars()
  -- genAurora() -- Generate aurora effects - removed
  -- Station initialization moved to space_station.lua
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
  -- drawAurora(gameState.t) -- removed

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

  -- movement waypoint (expanding ring) - UNDER the player
  if playerEntity.moveTarget and not playerEntity.docked then
    -- Calculate expansion progress (simulate timer for visual effect)
    local time = love.timer.getTime()
    local pulseSpeed = 2 -- rings per second
    local progress = (time * pulseSpeed) % 1 -- 0 to 1 cycle

    love.graphics.setColor(0.4, 1, 0.9, 0.6)
    local tx, ty = playerEntity.moveTarget.x, playerEntity.moveTarget.y

    -- Expanding ring effect
    local minRadius = 10
    local maxRadius = 35
    local currentRadius = minRadius + (maxRadius - minRadius) * progress

    love.graphics.setLineWidth(2)
    love.graphics.circle("line", tx, ty, currentRadius)

    -- Add a secondary smaller ring for more visual interest
    local secondaryRadius = minRadius + (maxRadius - minRadius) * ((progress + 0.5) % 1)
    love.graphics.setColor(0.4, 1, 0.9, 0.3)
    love.graphics.circle("line", tx, ty, secondaryRadius)
  end

  -- station
  spaceStation.draw()

  loot.draw()
  enemies.draw()
  player.draw()

  -- projectiles top so they render above ships
  projectiles.draw()

  -- particles (drawn over everything)
  love.graphics.push()
  love.graphics.origin()
  for _,p in ipairs(particles) do
    local r, g, b, a = unpack(p.color or {1,1,1,1})
    love.graphics.setColor(r, g, b, a * math.max(0, math.min(1, p.life)))
    love.graphics.circle("fill", p.x - camera.x + W/2, p.y - camera.y + H/2, p.size or 2)
  end
  love.graphics.pop()
  love.graphics.setColor(1,1,1,1)

  -- target indicator removed - spinning crosshairs disabled
end

return M
