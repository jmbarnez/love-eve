
-- DarkOrbit-style Single Player (Refactored) — LÖVE 11.x
-- No premium currencies. Single-player only.
-- By ChatGPT (GPL-3.0-or-later)

local ctx      = require("src.core.ctx")
local settings = require("src.core.settings")
local camera   = require("src.core.camera")
local save     = require("src.core.save")
local util     = require("src.core.util")

local player   = require("src.entities.player")
local enemies  = require("src.entities.enemy")
local bullets  = require("src.entities.bullet")
local loot     = require("src.entities.loot")

local hud      = require("src.render.hud")
local world    = require("src.render.world")
local dock     = require("src.ui.dock")

function love.load()
  love.window.setTitle("DarkOrbit-like (Single Player, Refactored)")
  love.window.setMode(1280, 720, {resizable=true, vsync=1})

  ctx.G = settings.build()
  ctx.state = { t = 0, paused=false, showHelp=true, autopilotFollowMouse=false, minimapExpanded=false, autosaveTimer=0 }
  ctx.fonts = {
    small = love.graphics.newFont(12),
    normal = love.graphics.newFont(14),
    big = love.graphics.newFont(20),
  }
  love.graphics.setFont(ctx.fonts.normal)

  world.init()
  player.init()
  enemies.init()
  dock.init()

  -- Attempt to load existing save
  save.load()
end

function love.update(dt)
  if ctx.state.paused then return end
  dt = math.min(dt, 1/30)
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
    bullets.update(dt)
    loot.update(dt)
  end
end

function love.draw()
  camera.push()
  world.draw()
  camera.pop()

  hud.draw()
  if ctx.player.docked then dock.draw() end

  if ctx.state.paused then
    local lg = love.graphics
    lg.push(); lg.origin()
    lg.setColor(0,0,0,0.5); lg.rectangle("fill", 0,0, lg.getWidth(), lg.getHeight())
    lg.setColor(1,1,1,1); lg.printf("Paused", 0, lg.getHeight()/2-40, lg.getWidth(), "center")
    lg.pop()
  end
end

function love.keypressed(key)
  if key == "escape" then ctx.state.paused = not ctx.state.paused end
  if key == "tab" then ctx.state.minimapExpanded = not ctx.state.minimapExpanded end
  if key == "h" then ctx.state.showHelp = not ctx.state.showHelp end
  if key == "space" then ctx.player.vx, ctx.player.vy = ctx.player.vx*0.2, ctx.player.vy*0.2 end
  if key == "f" then ctx.state.autopilotFollowMouse = not ctx.state.autopilotFollowMouse end
  if key == "f5" then save.save() end
  if key == "f9" then save.load() end
  if key == "e" then
    local dx,dy = ctx.player.x - ctx.station.x, ctx.player.y - ctx.station.y
    if util.len(dx,dy) < 120 then ctx.player.docked = not ctx.player.docked end
  end
end

function love.mousepressed(x,y,btn)
  if ctx.player.docked then
    if btn == 1 then dock.click(x, y) end
    return
  end
end

function love.quit()
  save.save()
end
