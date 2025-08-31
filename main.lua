<<<<<<< HEAD

=======
>>>>>>> a91d4cc (Fixed combat and movement)
-- DarkOrbit-style Single Player (Refactored) — LÖVE 11.x
-- No premium currencies. Single-player only.
-- By ChatGPT (GPL-3.0-or-later)

local ctx      = require("src.core.state")
local settings = require("src.core.settings")
local camera   = require("src.core.camera")
local save     = require("src.core.persistence.save")
local util     = require("src.core.util")

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

  ctx.G = settings.build()
  ctx.state = { t = 0, paused=false, showHelp=true, autosaveTimer=0 }
  ctx.fonts = {
    small = love.graphics.newFont(12),
    normal = love.graphics.newFont(14),
    big = love.graphics.newFont(20),
  }
  love.graphics.setFont(ctx.fonts.normal)

  world.init()
  player.init()
  enemies.init()
  projectiles.init()
  dock.init()
  simpleUI.init()

  -- Attempt to load existing save
  save.load()
<<<<<<< HEAD
=======

  -- ctx.state.fireTimer = 0  -- Removed: Using player's fireCooldown system instead
  -- ctx.G.TIME_SCALE = 0.5   -- Removed: No time scaling needed
>>>>>>> a91d4cc (Fixed combat and movement)
end

function love.update(dt)
  if ctx.state.paused then return end
<<<<<<< HEAD
  dt = math.min(dt, 1/30)
=======
  dt = math.min(dt, 1/30)  -- Cap delta time to prevent large jumps
>>>>>>> a91d4cc (Fixed combat and movement)
  ctx.state.t = ctx.state.t + dt
  ctx.state.autosaveTimer = ctx.state.autosaveTimer + dt
  if ctx.state.autosaveTimer > ctx.G.AUTOSAVE_INTERVAL then
    ctx.state.autosaveTimer = 0
    save.save()
  end

  camera.update(dt)

  if ctx.player.docked then
    player.regenDocked(dt)
  else
    player.update(dt)
    enemies.update(dt)
    projectiles.update(dt)
    loot.update(dt)
    lootBox.update(dt)
  end
  
  simpleUI.update(dt)
<<<<<<< HEAD
=======
  
  -- Removed fireTimer update - using player's fireCooldown system instead
>>>>>>> a91d4cc (Fixed combat and movement)
end

function love.draw()
  camera.push()
  world.draw()
  lootBox.draw()  -- Draw loot boxes
  camera.pop()

  -- Minimal Sci-Fi HUD System
  if ctx.player.docked then dock.draw() end
  
  simpleUI.draw()

  if ctx.state.paused then
    local lg = love.graphics
    lg.push(); lg.origin()
    lg.setColor(0,0,0,0.5); lg.rectangle("fill", 0,0, lg.getWidth(), lg.getHeight())
    lg.setColor(1,1,1,1); lg.printf("Paused", 0, lg.getHeight()/2-40, lg.getWidth(), "center")
    lg.pop()
  end
end

function love.keypressed(key)
  -- Let UI handle input first
  if simpleUI.keypressed(key) then return end
  
  if key == "escape" then ctx.state.paused = not ctx.state.paused end
  -- Tab now opens inventory (handled by UI)
  if key == "h" then ctx.state.showHelp = not ctx.state.showHelp end
  if key == "space" then ctx.player.vx, ctx.player.vy = ctx.player.vx*0.2, ctx.player.vy*0.2 end
  if key == "f5" then save.save() end
  if key == "f9" then save.load() end
<<<<<<< HEAD
=======
  if key == "c" then ctx.player.attackTarget = nil end -- Clear attack target
>>>>>>> a91d4cc (Fixed combat and movement)
  if key == "e" then
    local dx,dy = ctx.player.x - ctx.station.x, ctx.player.y - ctx.station.y
    if util.len(dx,dy) < 320 then ctx.player.docked = not ctx.player.docked end
  end
<<<<<<< HEAD
=======
  -- Removed manual fire key - using auto-attack system instead
>>>>>>> a91d4cc (Fixed combat and movement)
end

function love.mousepressed(x,y,btn)
  -- Let UI handle mouse input first
  if simpleUI.mousepressed(x, y, btn) then return end
  
  if ctx.player.docked then
    if btn == 1 then dock.click(x, y) end
    return
  end
  if btn == 1 then
<<<<<<< HEAD
    -- Left click to fire rocket toward mouse
    player.fireRocket(x, y)
=======
    -- Left click: set attack target if clicking on enemy
    local enemy = player.getEnemyUnderMouse()
    if enemy then
      player.setAttackTarget(enemy)
    end
>>>>>>> a91d4cc (Fixed combat and movement)
  elseif btn == 2 then
    -- Right click to move
    local lg = love.graphics
    local wx = ctx.camera.x + (x - lg.getWidth()/2)/ctx.G.ZOOM
    local wy = ctx.camera.y + (y - lg.getHeight()/2)/ctx.G.ZOOM
    player.setMoveTarget(wx, wy)
  end
end

function love.mousereleased(x, y, btn)
  if simpleUI.mousereleased(x, y, btn) then return end
end

function love.quit()
  save.save()
end
