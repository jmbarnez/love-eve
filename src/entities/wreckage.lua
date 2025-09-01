-- Wreckage Entity
-- Handles floating ship wreckage after enemy destruction

local state = require("src.core.state")
local util = require("src.core.util")

local M = {}

function M.init()
  state.set("wreckage", {})
end

-- Create a new wreckage piece
function M.create(x, y, variant, rotation, contents)
  local wreckage = state.get("wreckage")
  local piece = {
    x = x + (love.math.random() * 2 - 1) * 20,
    y = y + (love.math.random() * 2 - 1) * 20,
    vx = (love.math.random() * 2 - 1) * 50,
    vy = (love.math.random() * 2 - 1) * 50,
    r = rotation + (love.math.random() * 2 - 1) * 0.5,
    vr = (love.math.random() * 2 - 1) * 2, -- rotation speed
    life = 120, -- 2 minutes at 60fps
    maxLife = 120,
    variant = variant or "standard",
    pieces = M.generatePieces(variant or "standard"),
    contents = contents or {}, -- Loot contents
    radius = 30, -- Larger interaction radius for detailed wreckage
    canInteract = false
  }
  table.insert(wreckage, piece)

  -- Spawn loot items immediately around the wreckage
  if next(piece.contents) ~= nil then
    M.spawnLootFromWreckage(piece)
  end
end

-- Generate ship-specific wreckage pieces
function M.generatePieces(variant)
  local pieces = {}
  local numPieces = love.math.random(6, 12) -- More pieces for detail

  -- Ship-specific piece types based on variant
  local pieceTypes = {
    standard = {"hull", "appendage", "eye", "detail", "engine"},
    aggressive = {"hull", "appendage", "eye", "weapon", "armor"},
    sniper = {"hull", "appendage", "sensor", "barrel", "detail"},
    bruiser = {"hull", "appendage", "armor", "engine", "bulkhead"}
  }

  local types = pieceTypes[variant] or pieceTypes.standard

  for i = 1, numPieces do
    local pieceType = types[love.math.random(#types)]
    local piece = {
      offsetX = (love.math.random() * 2 - 1) * 25,
      offsetY = (love.math.random() * 2 - 1) * 25,
      size = love.math.random(3, 10),
      type = pieceType,
      rotation = love.math.random() * math.pi * 2,
      variant = variant,
      -- Add some variation to make pieces unique
      scaleX = 0.8 + love.math.random() * 0.4,
      scaleY = 0.8 + love.math.random() * 0.4,
      damage = love.math.random() * 0.6 -- 0-60% damage for torn/broken look
    }
    table.insert(pieces, piece)
  end

  return pieces
end

-- Helper functions for variant-specific colors
function M.getVariantColor(variant)
  local colors = {
    standard = {0.8, 0.1, 0.2},
    aggressive = {0.9, 0.2, 0.2},
    sniper = {0.6, 0.2, 0.8},
    bruiser = {0.8, 0.4, 0.1}
  }
  return colors[variant] or colors.standard
end

function M.getAppendageColor(variant)
  local colors = {
    standard = {0.6, 0.05, 0.15},
    aggressive = {0.6, 0.3, 0.1},
    sniper = {0.4, 0.1, 0.6},
    bruiser = {0.6, 0.3, 0.1}
  }
  return colors[variant] or colors.standard
end

function M.getEyeColor(variant)
  local colors = {
    standard = {1.0, 0.3, 0.1},
    aggressive = {1.0, 0.4, 0.2},
    sniper = {1.0, 0.2, 1.0},
    bruiser = {1.0, 0.6, 0.2}
  }
  return colors[variant] or colors.standard
end

function M.update(dt)
  local wreckage = state.get("wreckage")
  local player = state.get("player")
  local mx, my = love.mouse.getPosition()
  local camera = state.get("camera")
  local gameState = state.get("gameState")
  local wx = camera.x + (mx - love.graphics.getWidth()/2)/gameState.zoom
  local wy = camera.y + (my - love.graphics.getHeight()/2)/gameState.zoom

  for i = #wreckage, 1, -1 do
    local w = wreckage[i]

    -- Apply physics
    w.vx = w.vx * 0.98 -- friction
    w.vy = w.vy * 0.98
    w.x = w.x + w.vx * dt
    w.y = w.y + w.vy * dt
    w.r = w.r + w.vr * dt

    -- Fade out rotation speed
    w.vr = w.vr * 0.95

    -- Check for player interaction
    local dx = wx - w.x
    local dy = wy - w.y
    local dist = math.sqrt(dx*dx + dy*dy)
    w.canInteract = dist < w.radius and next(w.contents) ~= nil

    -- Decrease life
    w.life = w.life - dt

    -- Remove when life expires
    if w.life <= 0 then
      table.remove(wreckage, i)
    end
  end
end

function M.draw()
  local wreckage = state.get("wreckage")

  for _, w in ipairs(wreckage) do
    local alpha = math.min(1, w.life / 30) -- fade out in last 30 seconds

    love.graphics.push()
    love.graphics.translate(w.x, w.y)
    love.graphics.rotate(w.r)

    -- Draw wreckage pieces with ship-specific details
    for _, piece in ipairs(w.pieces) do
      love.graphics.push()
      love.graphics.translate(piece.offsetX, piece.offsetY)
      love.graphics.rotate(piece.rotation)
      love.graphics.scale(piece.scaleX, piece.scaleY)

      -- Ship-specific piece rendering based on variant and type
      if piece.type == "hull" then
        -- Main hull fragments - irregular organic shapes
        local variantColor = M.getVariantColor(w.variant)
        love.graphics.setColor(variantColor[1] * 0.6, variantColor[2] * 0.6, variantColor[3] * 0.6, alpha * 0.9)
        love.graphics.polygon("fill",
          piece.size, 0,
          -piece.size * 0.7, piece.size * 0.5,
          -piece.size * 0.7, -piece.size * 0.5,
          -piece.size * 0.3, 0
        )
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.polygon("line",
          piece.size, 0,
          -piece.size * 0.7, piece.size * 0.5,
          -piece.size * 0.7, -piece.size * 0.5,
          -piece.size * 0.3, 0
        )

      elseif piece.type == "appendage" then
        -- Alien tentacles/appendages
        local appendageColor = M.getAppendageColor(w.variant)
        love.graphics.setColor(appendageColor[1], appendageColor[2], appendageColor[3], alpha * 0.8)
        love.graphics.polygon("fill",
          piece.size * 0.8, 0,
          -piece.size * 0.6, piece.size * 0.3,
          -piece.size * 0.6, -piece.size * 0.3,
          -piece.size * 0.2, 0
        )
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.polygon("line",
          piece.size * 0.8, 0,
          -piece.size * 0.6, piece.size * 0.3,
          -piece.size * 0.6, -piece.size * 0.3,
          -piece.size * 0.2, 0
        )

      elseif piece.type == "eye" or piece.type == "sensor" then
        -- Glowing eyes/sensors
        local eyeColor = M.getEyeColor(w.variant)
        love.graphics.setColor(eyeColor[1], eyeColor[2], eyeColor[3], alpha)
        love.graphics.circle("fill", 0, 0, piece.size)
        love.graphics.setColor(1.0, 0.8, 0.2, alpha * 0.8)
        love.graphics.circle("fill", 0, 0, piece.size * 0.6)
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.circle("line", 0, 0, piece.size)

      elseif piece.type == "engine" then
        -- Engine fragments
        love.graphics.setColor(0.15, 0.15, 0.15, alpha * 0.8)
        love.graphics.circle("fill", 0, 0, piece.size)
        love.graphics.setColor(0.05, 0.05, 0.05, alpha)
        love.graphics.circle("line", 0, 0, piece.size)
        love.graphics.circle("line", 0, 0, piece.size * 0.6)
        -- Add some engine glow
        love.graphics.setColor(1.0, 0.3, 0.1, alpha * 0.4)
        love.graphics.circle("fill", 0, 0, piece.size * 0.8)

      elseif piece.type == "weapon" or piece.type == "barrel" then
        -- Weapon barrels
        love.graphics.setColor(0.2, 0.2, 0.2, alpha * 0.8)
        love.graphics.rectangle("fill", -piece.size, -piece.size * 0.3, piece.size * 2, piece.size * 0.6)
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.rectangle("line", -piece.size, -piece.size * 0.3, piece.size * 2, piece.size * 0.6)

      elseif piece.type == "armor" then
        -- Armor plating
        love.graphics.setColor(0.25, 0.25, 0.25, alpha * 0.8)
        love.graphics.polygon("fill",
          piece.size, piece.size,
          -piece.size, piece.size,
          -piece.size, -piece.size,
          piece.size, -piece.size
        )
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.polygon("line",
          piece.size, piece.size,
          -piece.size, piece.size,
          -piece.size, -piece.size,
          piece.size, -piece.size
        )

      elseif piece.type == "bulkhead" then
        -- Internal bulkheads
        love.graphics.setColor(0.18, 0.18, 0.18, alpha * 0.8)
        love.graphics.rectangle("fill", -piece.size, -piece.size, piece.size * 2, piece.size * 2)
        love.graphics.setColor(0.08, 0.08, 0.08, alpha)
        love.graphics.rectangle("line", -piece.size, -piece.size, piece.size * 2, piece.size * 2)

      else -- "detail" or fallback
        -- Miscellaneous details
        love.graphics.setColor(0.22, 0.22, 0.22, alpha * 0.8)
        love.graphics.circle("fill", 0, 0, piece.size)
        love.graphics.setColor(0.1, 0.1, 0.1, alpha)
        love.graphics.circle("line", 0, 0, piece.size)
      end

      -- Add damage effects (torn edges, holes)
      if piece.damage > 0.3 then
        love.graphics.setColor(0.1, 0.1, 0.1, alpha * 0.6)
        love.graphics.circle("fill", piece.size * 0.5, 0, piece.size * 0.2)
      end

      love.graphics.pop()
    end

    love.graphics.pop()
  end
end

-- Handle right-click interaction with wreckage
function M.handleRightClick(x, y)
  local wreckage = state.get("wreckage")
  local camera = state.get("camera")
  local gameState = state.get("gameState")
  local wx = camera.x + (x - love.graphics.getWidth()/2)/gameState.zoom
  local wy = camera.y + (y - love.graphics.getHeight()/2)/gameState.zoom

  for _, w in ipairs(wreckage) do
    if w.canInteract then
      local dx = wx - w.x
      local dy = wy - w.y
      local dist = math.sqrt(dx*dx + dy*dy)

      if dist < w.radius then
        -- Loot is already spawned immediately when wreckage is created
        -- No need to spawn again on right-click
        return true -- Handled the click
      end
    end
  end

  return false -- No wreckage clicked
end

-- Spawn physical loot items around wreckage
function M.spawnLootFromWreckage(wreckage)
  local loot = require("src.entities.loot")
  local items = require("src.content.items.registry")

  -- Collect items to spawn (exclude credits) to compute proper angular spread
  local itemsToSpawn = {}
  for itemType, itemData in pairs(wreckage.contents) do
    if itemType ~= "credits" and itemData.quantity > 0 then
      table.insert(itemsToSpawn, { id = itemType, qty = itemData.quantity })
      -- Clear from wreckage contents
      wreckage.contents[itemType] = nil
    end
  end

  local count = #itemsToSpawn
  if count > 0 then
    for i, entry in ipairs(itemsToSpawn) do
      -- Evenly spread with slight random jitter
      local baseAngle = (i - 1) / count * (2 * math.pi)
      local angle = baseAngle + (love.math.random() * 0.6 - 0.3) -- ±0.3 rad jitter
      local distance = 40 + (i * 5) + love.math.random() * 20
      local itemX = wreckage.x + math.cos(angle) * distance
      local itemY = wreckage.y + math.sin(angle) * distance
      loot.createItem(itemX, itemY, entry.id, entry.qty)
    end
  end

  -- Add credits as bounty
  if wreckage.contents.credits and wreckage.contents.credits > 0 then
    M.addBounty(wreckage.contents.credits)
    wreckage.contents.credits = 0
  end
end

-- Add credits to bounty system
function M.addBounty(amount)
  local bounties = state.get("bounties") or {}
  table.insert(bounties, {
    amount = amount,
    timestamp = love.timer.getTime(),
    claimed = false
  })
  state.set("bounties", bounties)
end

-- Get total unclaimed bounty
function M.getTotalBounty()
  local bounties = state.get("bounties") or {}
  local total = 0
  for _, bounty in ipairs(bounties) do
    if not bounty.claimed then
      total = total + bounty.amount
    end
  end
  return total
end

-- Claim all bounties
function M.claimBounties()
  local bounties = state.get("bounties") or {}
  local totalClaimed = 0
  local player = state.get("player")

  for _, bounty in ipairs(bounties) do
    if not bounty.claimed then
      player.credits = player.credits + bounty.amount
      totalClaimed = totalClaimed + bounty.amount
      bounty.claimed = true
    end
  end

  return totalClaimed
end

return M
