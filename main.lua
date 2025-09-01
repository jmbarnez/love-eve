-- DarkOrbit-style Single Player (Refactored) — LÖVE 11.x

local state = require("src.core.state")
local camera = require("src.core.camera")
local util = require("src.core.util")

local player   = require("src.entities.player")
local enemies  = require("src.entities.enemy")
local spaceStation = require("src.entities.space_station")
local projectiles = require("src.systems.projectiles")
local loot     = require("src.entities.loot")
local wreckage = require("src.entities.wreckage")

local world    = require("src.render.world")
-- local dock     = require("src.ui.dock_window")
local simpleUI = require("src.ui.simple_ui")
local modules = require("src.systems.modules")
local debug_console = require("src.ui.debug_console")
local settings_panel = require("src.ui.panels.settings")

function love.load()
  love.window.setTitle("DarkOrbit-like (Single Player, Refactored)")
  love.window.setMode(1280, 720, {resizable=true, vsync=true})
  love.graphics.setDefaultFilter("nearest", "nearest")
  
  -- Create a smaller font for loot labels
  local defaultFont = love.graphics.getFont()
  state.set("smallFont", love.graphics.newFont(10)) -- Create a 10px font

  -- Initialize game state
  state.init()

  local gameState = state.get("gameState")
  local config = state.get("config") or require("src.core.config") or { game = { ZOOM = 1.0 } }
  gameState.G = config.game or { ZOOM = 1.0 }

  world.init()
  player.init()
  enemies.init()
  spaceStation.init()
  loot.init()
  projectiles.init()
  -- dock.init()
  simpleUI.init()
  wreckage.init()
  modules.init()

  -- Initialize continuous movement state
  gameState.rightMouseHeld = false
  gameState.zoom = gameState.G.ZOOM or 1.2  -- Initialize zoom

end

function love.update(dt)
  local gameState = state.get("gameState")
  local gameConfig = state.get("config").game
  local playerEntity = state.get("player")

  if gameState.paused then return end
  dt = math.min(dt, 1/30)  -- Cap delta time to prevent large jumps
  gameState.t = gameState.t + dt

  -- Handle continuous right-click movement
  if gameState.rightMouseHeld and playerEntity and not playerEntity.docked then
    local mx, my = love.mouse.getPosition()
    local lg = love.graphics
    local camera = state.get("camera")
    local wx = camera.x + (mx - lg.getWidth()/2)/gameState.zoom
    local wy = camera.y + (my - lg.getHeight()/2)/gameState.zoom
    player.setMoveTarget(wx, wy)
  end

  camera.update(dt)

  if playerEntity.docked then
    player.regenDocked(dt)
  else
    player.update(dt)
    enemies.update(dt)
    spaceStation.update(dt)
    projectiles.update(dt)
    loot.update(dt)
    wreckage.update(dt)
    modules.update(dt)
  end
  
  simpleUI.update(dt)
  debug_console.update(dt)

  -- Update particles
  local particles = state.get("particles")
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then
      table.remove(particles, i)
    end
  end
end

function love.draw()
  local gameState = state.get("gameState")

  camera.push()
  world.draw()
  enemies.draw()
  wreckage.draw()
  projectiles.draw()
  loot.draw()
  camera.pop()

  -- Minimal Sci-Fi HUD System
  local playerEntity = state.get("player")
  -- if playerEntity.docked then dock.draw() end
  
  simpleUI.draw()
  debug_console.draw()

  if gameState.paused and not settings_panel.isOpen() then
    local lg = love.graphics
    lg.push(); lg.origin()
    lg.setColor(0,0,0,0.5); lg.rectangle("fill", 0,0, lg.getWidth(), lg.getHeight())
    lg.setColor(1,1,1,1); lg.printf("Paused", 0, lg.getHeight()/2-40, lg.getWidth(), "center")
    lg.pop()
  end
end

function love.keypressed(key)
  local gameState = state.get("gameState")

  -- Let debug console handle keyboard input first
  if debug_console.keypressed(key) then return end

  -- Let UI handle input first
  if simpleUI.keypressed(key) then return end
  
  if key == "escape" then settings_panel.toggle(); return end
  -- Tab now opens inventory (handled by UI)
  if key == "h" then gameState.showHelp = not gameState.showHelp end
  if key == "space" then
    local playerEntity = state.get("player")
    playerEntity.vx, playerEntity.vy = playerEntity.vx*0.9, playerEntity.vy*0.9
  end
  if key == "`" then
    debug_console.toggle()
  end
  if key == "d" then
    local playerEntity = state.get("player")
    local station = state.get("station")
    local dx,dy = playerEntity.x - station.x, playerEntity.y - station.y
    if util.len(dx,dy) < 320 then playerEntity.docked = not playerEntity.docked end
  end
  -- Zoom controls
  if key == "=" or key == "+" then
    gameState.zoom = math.min(2.0, gameState.zoom * 1.2)
  elseif key == "-" then
    gameState.zoom = math.max(0.5, gameState.zoom / 1.2)
  end
  -- Hotbar controls (q, w, e, r)
  if key == "q" then
    debug_console.log("Activating module 1 from main.lua")
    modules.activate_module(1)
  elseif key == "w" then
    modules.activate_module(2)
  elseif key == "e" then
    modules.activate_module(3)
  elseif key == "r" then
    modules.activate_module(4)
  end
  -- Removed manual fire key - using auto attack system instead
end

function love.mousepressed(x,y,btn)
  local playerEntity = state.get("player")
  local gameState = state.get("gameState")

  -- Let debug console handle mouse input first
  if debug_console.mousepressed(x, y, btn) then return end

  -- Let UI handle mouse input first
  if simpleUI.mousepressed(x, y, btn) then return end
  
  if playerEntity.docked then
    -- if btn == 1 then dock.click(x, y) end
    return
  end
  if btn == 1 then
    -- Left click: set attack target if clicking on enemy, or collect loot
    local loot = require("src.entities.loot")
    if loot.handleLeftClick(x, y) then
      return -- Loot collection handled
    end

    local enemy = player.getEnemyUnderMouse()
    if enemy then
      player.setAttackTarget(enemy)
    end
  elseif btn == 2 then
    -- Right click to start continuous movement or interact with wreckage
    local wreckage = require("src.entities.wreckage")
    if not wreckage.handleRightClick(x, y) then
      -- If not clicking on wreckage, start continuous movement
      gameState.rightMouseHeld = true
      local lg = love.graphics
      local camera = state.get("camera")
      local wx = camera.x + (x - lg.getWidth()/2)/gameState.zoom
      local wy = camera.y + (y - lg.getHeight()/2)/gameState.zoom
      player.setMoveTarget(wx, wy)
    end
  end
end

function love.mousereleased(x, y, btn)
  local gameState = state.get("gameState")
  
  -- Let debug console handle mouse release first
  debug_console.mousereleased(x, y, btn)
  
  if simpleUI.mousereleased(x, y, btn) then return end
  
  if btn == 2 then
    -- Stop continuous movement when right mouse is released
    gameState.rightMouseHeld = false
  end
end

function love.mousemoved(x, y, dx, dy)
  debug_console.mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
  local gameState = state.get("gameState")
  
  -- Let debug console handle scrolling first (and consume event if handled)
  if debug_console.mousewheelmoved(x, y) then
    return -- Don't zoom if console handled the scroll
  end
  
  -- Then handle zoom
  if y > 0 then
    -- Zoom in
    gameState.zoom = math.min(2.0, gameState.zoom * 1.2)
  elseif y < 0 then
    -- Zoom out
    gameState.zoom = math.max(0.5, gameState.zoom / 1.2)
  end
end

function love.quit()
end
