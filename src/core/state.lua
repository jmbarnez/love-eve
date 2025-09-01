
local serviceLocator = require("src.core.service_locator")
local eventSystem = require("src.core.event_system")
local assetManager = require("src.core.asset_manager")
local config = require("src.core.config")

local M = {}

-- Initialize the game state
function M.init()
  -- Register core services
  serviceLocator.register("eventSystem", eventSystem)
  serviceLocator.register("assetManager", assetManager)
  serviceLocator.register("config", config)

  -- Game state
  local state = {
    t = 0,
    paused = false,
    showHelp = true,
  }
  serviceLocator.register("gameState", state)

  -- Camera
  local camera = {x = 0, y = 0, shake = 0}
  serviceLocator.register("camera", camera)

  -- Fonts - Modern Retro Style (Pixel-Perfect with Crisp Edges)
  local fonts = {
    small = love.graphics.newFont(12),
    normal = love.graphics.newFont(14),
    big = love.graphics.newFont(20),
  }

  -- Configure fonts for modern retro appearance
  for name, font in pairs(fonts) do
    -- Set pixel-perfect filtering for crisp, retro look
    font:setFilter("nearest", "nearest")
  end

  -- Set font rendering to be crisp for retro pixel-perfect look
  love.graphics.setDefaultFilter("nearest", "nearest", 1) -- Pixel-perfect scaling for modern retro aesthetic
  love.graphics.setFont(fonts.normal)
  serviceLocator.register("fonts", fonts)

  -- UI state
  serviceLocator.register("containerOpen", false)
  serviceLocator.register("currentContainer", nil)

  -- Initialize game data arrays used by entities
  serviceLocator.register("lootBoxes", {})
  serviceLocator.register("notifications", {})
  serviceLocator.register("particles", {})
end

-- Get service by name
function M.get(name)
  return serviceLocator.get(name)
end

-- Set service
function M.set(name, value)
  serviceLocator.register(name, value)
end

return M
