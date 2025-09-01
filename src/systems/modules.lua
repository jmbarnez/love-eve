local state = require("src.core.state")
local util = require("src.core.util")
local items = require("src.content.items.registry")

local M = {}

-- This will hold the state of all active modules equipped by the player
local active_modules = {}

-- Initialize the module system
function M.init()
    M.recalculate_modules()
end

-- Recalculate and set up modules based on player's equipment
function M.recalculate_modules()
    local player = state.get("player")
    active_modules = {}

    if not player or not player.equipment then return end

    for slotId, itemId in pairs(player.equipment) do
        local itemDef = items.get(itemId)
        if itemDef and itemDef.module_type == "active" then
            table.insert(active_modules, {
                id = itemId,
                slot = slotId,
                cooldown = 0,
                duration = itemDef.duration or 0,
                state = "ready", -- ready, active, cooldown
                def = itemDef,
            })
        end
    end
end

-- Update all active modules
function M.update(dt)
    local player = require("src.entities.player")
    for _, module in ipairs(active_modules) do
        if module.state == "active" then
            if module.def.effect == "fire_turret" then
                player.fire_turret()
            else
                -- Existing duration/cooldown logic for other module types
                module.duration = module.duration - dt
                if module.duration <= 0 then
                    module.state = "cooldown"
                    module.cooldown = module.def.cooldown or 5
                    -- Deactivate effect if any
                end
            end
        elseif module.state == "cooldown" then
            module.cooldown = module.cooldown - dt
            if module.cooldown <= 0 then
                module.state = "ready"
            end
        end
    end
end

-- Attempt to activate a module by its slot index (e.g., 1 for 'Q')
function M.activate_module(index)
    if not active_modules[index] then return false end

    local module = active_modules[index]

    -- Toggle logic for turrets
    if module.def.effect == "fire_turret" then
        if module.state == "ready" then
            module.state = "active"
            print("Activated module: " .. module.id)
        elseif module.state == "active" then
            module.state = "ready"
            print("Deactivated module: " .. module.id)
        end
        return true
    end

    -- Existing logic for other modules
    if module.state == "ready" then
        local player = state.get("player")
        local energy_cost = module.def.energy_cost or 0

        if player.energy >= energy_cost then
            player.energy = player.energy - energy_cost
            module.state = "active"
            module.duration = module.def.duration or 0
            
            print("Activated module: " .. module.id)
            return true
        else
            print("Not enough energy to activate module: " .. module.id)
            return false
        end
    end
    return false
end

function M.get_modules()
    return active_modules
end

return M
