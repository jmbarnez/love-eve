-- DarkOrbit-style Single Player (Refactored) — LÖVE 11.x

local state = require("src.core.state")
local settings = require("src.core.settings")
local camera = require("src.core.camera")
local save = require("src.core.persistence.save")
local util = require("src.core.util")

local player   = require("src.entities.player")
local enemies  = require("src.entities.enemy")
local projectiles = require("src.systems.projectiles")
local loot     = require("src.entities.loot")
local lootBox  = require("src.entities.loot_box")

local world    = require("src.render.world")
local dock     = require("src.ui.dock_window")
local simpleUI = require("src.ui.simple_ui")

function love.load()
  love.window.setTitle("DarkOrbit-like (Single Player, Refactored)")
  love.window.setMode(0, 0, {fullscreen=true, resizable=true, vsync=1})
  love.graphics.setDefaultFilter("nearest", "nearest")

  -- Initialize state system
  state.init()

  local gameState = state.get("gameState")
  local config = state.get("config") or require("src.core.config") or { game = { AUTOSAVE_INTERVAL = 60, ZOOM = 1.0 } }
  gameState.G = config.game or { AUTOSAVE_INTERVAL = 60, ZOOM = 1.0 }

  world.init()
  player.init()
  enemies.init()
  loot.init()
  projectiles.init()
  dock.init()
  simpleUI.init()

  -- Attempt to load existing save
  save.load()
end

function love.update(dt)
  local gameState = state.get("gameState")
  local config = state.get("config") or require("src.core.config") or { game = { AUTOSAVE_INTERVAL = 60, ZOOM = 1.0 } }
  local gameConfig = config.game or { AUTOSAVE_INTERVAL = 60, ZOOM = 1.0 }

  if gameState.paused then return end
  dt = math.min(dt, 1/30)  -- Cap delta time to prevent large jumps
  gameState.t = gameState.t + dt
  gameState.autosaveTimer = gameState.autosaveTimer + dt
  if gameState.autosaveTimer > gameConfig.AUTOSAVE_INTERVAL then
    gameState.autosaveTimer = 0
    save.save()
  end

  camera.update(dt)

  local playerEntity = state.get("player")
  if playerEntity.docked then
    player.regenDocked(dt)
  else
    player.update(dt)
    enemies.update(dt)
    projectiles.update(dt)
    loot.update(dt)
    lootBox.update(dt)
  end
  
  simpleUI.update(dt)
end

function love.draw()
  local gameState = state.get("gameState")

  camera.push()
  world.draw()
  camera.pop()

  -- Minimal Sci-Fi HUD System
  local playerEntity = state.get("player")
  if playerEntity.docked then dock.draw() end
  
  simpleUI.draw()

  if gameState.paused then
    local lg = love.graphics
    lg.push(); lg.origin()
    lg.setColor(0,0,0,0.5); lg.rectangle("fill", 0,0, lg.getWidth(), lg.getHeight())
    lg.setColor(1,1,1,1); lg.printf("Paused", 0, lg.getHeight()/2-40, lg.getWidth(), "center")
    lg.pop()
  end
end

function love.keypressed(key)
  local gameState = state.get("gameState")

  -- Let UI handle input first
  if simpleUI.keypressed(key) then return end
  
  if key == "escape" then gameState.paused = not gameState.paused end
  -- Tab now opens inventory (handled by UI)
  if key == "h" then gameState.showHelp = not gameState.showHelp end
  if key == "space" then
    local playerEntity = state.get("player")
    playerEntity.vx, playerEntity.vy = playerEntity.vx*0.2, playerEntity.vy*0.2
  end
  if key == "f5" then save.save() end
  if key == "f9" then save.load() end
  if key == "c" then
    local playerEntity = state.get("player")
    playerEntity.attackTarget = nil
  end
  if key == "e" then
    local playerEntity = state.get("player")
    local station = state.get("station")
    local dx,dy = playerEntity.x - station.x, playerEntity.y - station.y
    if util.len(dx,dy) < 320 then playerEntity.docked = not playerEntity.docked end
  end
  -- Removed manual fire key - using auto-attack system instead
end

function love.mousepressed(x,y,btn)
  local playerEntity = state.get("player")

  -- Let UI handle mouse input first
  if simpleUI.mousepressed(x, y, btn) then return end
  
  if playerEntity.docked then
    if btn == 1 then dock.click(x, y) end
    return
  end
  if btn == 1 then
    -- Left click: set attack target if clicking on enemy
    local enemy = player.getEnemyUnderMouse()
    if enemy then
      player.setAttackTarget(enemy)
    end
  elseif btn == 2 then
    -- Right click to move
    local lg = love.graphics
    local camera = state.get("camera")
    local config = state.get("config") or require("src.core.config") or { game = { ZOOM = 1.0 } }
    local gameConfig = config.game or { ZOOM = 1.0 }
    local wx = camera.x + (x - lg.getWidth()/2)/gameConfig.ZOOM
    local wy = camera.y + (y - lg.getHeight()/2)/gameConfig.ZOOM
    player.setMoveTarget(wx, wy)
  end
end

function love.mousereleased(x, y, btn)
  if simpleUI.mousereleased(x, y, btn) then return end
end

function love.quit()
  save.save()
end
