local state = require("src.core.state")
local util = require("src.core.util")
local items = require("src.content.items.registry")
local debug_console = require("src.ui.debug_console")

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
    local player = state.get("player")
    if not player then return end

    for _, module in ipairs(active_modules) do
        if module.state == "active" then
            if module.def.effect == "fire_turret" then
                module.cooldown = math.max(0, module.cooldown - dt)
                local target = player.attackTarget
                if target and target.hp > 0 then
                    local dist = util.distance(player.x, player.y, target.x, target.y)
                    if module.def.range and dist <= module.def.range then
                        if module.cooldown <= 0 then
                            require("src.entities.player").fire_turret(module.def)
                            module.cooldown = module.def.cooldown or 1
                        end
                    end
                end
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

-- Attempt to activate a module by hotbar index (0-9)
function M.activate_module(hotbar_index)
    -- Hotbar indices 1-10 correspond to keys 1-9,0
    if hotbar_index < 1 or hotbar_index > 10 then return false end
    
    -- Get the module at this hotbar position
    local module = active_modules[hotbar_index]
    if not module then
        return false
    end

    -- Toggle logic for turrets
    if module.def.effect == "fire_turret" then
        if module.state == "ready" then
            module.state = "active"
        elseif module.state == "active" then
            module.state = "ready" -- Set to ready when deactivated
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
            
            return true
        else
            return false
        end
    end
    return false
end

function M.get_modules()
    -- Return all active modules for hotbar display (up to 10)
    return active_modules
end

return M
