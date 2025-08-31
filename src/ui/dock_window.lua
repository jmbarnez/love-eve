
local ctx  = require("src.core.state")
local util = require("src.core.util")

local M = { buttons = {} }

local function add(label, cost, desc, apply)
  table.insert(M.buttons, {label=label, cost=cost, desc=desc, apply=apply})
end

function M.init()
  M.buttons = {}
  add("+10% Weapon Damage", 120, "Increase blaster damage by 10%", function()
    local player = ctx.get("player")
    player.damage = math.floor(player.damage * 1.10 + 0.5)
  end)
  add("+10% Fire Rate", 140, "Blaster fires faster", function()
    local player = ctx.get("player")
    player.fireCooldownMax = player.fireCooldownMax * 0.9
  end)
  add("+15% Shields", 180, "More max shields", function()
    local player = ctx.get("player")
    player.maxShield = math.floor(player.maxShield * 1.15 + 0.5); player.shield = player.maxShield
  end)
  add("+15% Hull", 160, "More max hull", function()
    local player = ctx.get("player")
    player.maxHP = math.floor(player.maxHP * 1.15 + 0.5); player.hp = player.maxHP
  end)
  add("+12% Engine", 150, "Higher top speed", function()
    local player = ctx.get("player")
    player.maxSpeed = player.maxSpeed * 1.12
  end)
  add("+15% Energy", 130, "More max energy", function()
    local player = ctx.get("player")
    player.maxEnergy = math.floor(player.maxEnergy * 1.15 + 0.5); player.energy = player.maxEnergy
  end)
  add("Shield Regen +20%", 110, "Faster shield recharge", function()
    local player = ctx.get("player")
    player.shieldRegen = player.shieldRegen * 1.2
  end)
  add("Energy Regen +25%", 130, "Faster energy recharge", function()
    local player = ctx.get("player")
    player.energyRegen = player.energyRegen * 1.25
  end)
end

function M.draw()
  love.graphics.push(); love.graphics.origin(); love.graphics.scale(ctx.G.UI_SCALE)
  local W,H = love.graphics.getWidth()/ctx.G.UI_SCALE, love.graphics.getHeight()/ctx.G.UI_SCALE
  love.graphics.setColor(0,0,0,0.6); love.graphics.rectangle("fill", 0,0, W,H)
  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("Docked — Upgrade Bay", 0, 40, W, "center")
  local player = ctx.get("player")
  love.graphics.printf("Credits: "..string.format("%.2f", player.credits), 0, 66, W, "center")

  local bx, by = W*0.5 - 360, 120
  for i,btn in ipairs(M.buttons) do
    local x = bx + ((i-1)%2)*360
    local y = by + math.floor((i-1)/2)*90
    local w,h = 340, 70
    love.graphics.setColor(0.16,0.18,0.2,0.9); love.graphics.rectangle("fill", x,y,w,h, 8,8)
    love.graphics.setColor(0.4,0.45,0.5,1); love.graphics.rectangle("line", x,y,w,h, 8,8)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(btn.label, x+16, y+12)
    love.graphics.setColor(1,0.9,0.4,1); love.graphics.print("Cost: "..btn.cost, x+16, y+36)
    love.graphics.setColor(0.85,0.9,1,1); love.graphics.printf(btn.desc, x+150, y+12, 180, "right")
    btn._rect = {x=x,y=y,w=w,h=h}
  end
  love.graphics.printf("Click to purchase. E to undock.", 0, H-40, W, "center")
  love.graphics.pop()
end

function M.click(x, y)
  -- transform to UI scale
  x, y = x/ctx.G.UI_SCALE, y/ctx.G.UI_SCALE
  local player = ctx.get("player")
  local camera = ctx.get("camera")
  for _,btn in ipairs(M.buttons) do
    local r = btn._rect
    if r and x>=r.x and y>=r.y and x<=r.x+r.w and y<=r.y+r.h then
      if player.credits >= btn.cost then
        player.credits = player.credits - btn.cost
        btn.apply()
        camera.shake = 0.2
      else
        camera.shake = 0.1
      end
      break
    end
  end
end

return M
