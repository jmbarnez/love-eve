-- Item Definition System
-- Centralized registry for all game items

local M = {}

-- Item categories
M.CATEGORIES = {
  CONSUMABLE = "consumable",
  WEAPON_AMMO = "weapon_ammo", 
  RARE = "rare",
  CURRENCY = "currency"
}

-- Item registry
M.items = {
  -- Consumables
  ["repair_kit"] = {
    id = "repair_kit",
    name = "Nanite Repair Paste",
    description = "Instantly repairs hull and shield damage",
    category = M.CATEGORIES.CONSUMABLE,
    value = 50,
    stackable = true,
    maxStack = 99,
    color = {0, 1, 0.5, 1}, -- Green
    effect = function(quantity)
      local ctx = require("src.core.state")
      ctx.player.hp = math.min(ctx.player.maxHP, ctx.player.hp + 50 * quantity)
      ctx.player.shield = math.min(ctx.player.maxShield, ctx.player.shield + 30 * quantity)
      return "+" .. (50 * quantity) .. " HP +" .. (30 * quantity) .. " Shield"
    end
  },
  
  -- Weapon Ammo
  
  -- Rare Items
  ["alien_tech"] = {
    id = "alien_tech",
    name = "Alien Technology Fragment",
    description = "Advanced alien technology. Purpose unknown.",
    category = M.CATEGORIES.RARE,
    value = 200,
    stackable = true,
    maxStack = 50,
    color = {1, 0.8, 0, 1}, -- Gold
  },
  
  ["quantum_core"] = {
    id = "quantum_core",
    name = "Quantum Core",
    description = "Highly unstable quantum energy core. Handle with care.",
    category = M.CATEGORIES.RARE,
    value = 1000,
    stackable = false,
    maxStack = 1,
    color = {1, 0.2, 1, 1}, -- Magenta
  },
  
  ["neural_implant"] = {
    id = "neural_implant",
    name = "Bio-Neural Implant",
    description = "Enhances pilot reaction time and accuracy",
    category = M.CATEGORIES.RARE,
    value = 750,
    stackable = false,
    maxStack = 1,
    color = {0.8, 1, 0.8, 1}, -- Light Green
  },
  
  -- More consumables
  ["shield_booster"] = {
    id = "shield_booster",
    name = "Shield Booster",
    description = "Temporarily increases shield capacity",
    category = M.CATEGORIES.CONSUMABLE,
    value = 75,
    stackable = true,
    maxStack = 25,
    color = {0.2, 0.8, 1, 1}, -- Cyan
    effect = function(quantity)
      local ctx = require("src.core.state")
      ctx.player.maxShield = ctx.player.maxShield + 20 * quantity
      ctx.player.shield = ctx.player.maxShield
      return "+" .. (20 * quantity) .. " Max Shield"
    end
  },
  
  ["energy_drink"] = {
    id = "energy_drink",
    name = "Hyperion Energy Drink",
    description = "Restores energy and increases regeneration rate",
    category = M.CATEGORIES.CONSUMABLE,
    value = 25,
    stackable = true,
    maxStack = 50,
    color = {1, 1, 0.2, 1}, -- Yellow
    effect = function(quantity)
      local ctx = require("src.core.state")
      ctx.player.energy = ctx.player.maxEnergy
      ctx.player.energyRegen = ctx.player.energyRegen + 2 * quantity
      return "Energy restored, +" .. (2 * quantity) .. " regen rate"
    end
  },

  -- EQUIPMENT MODULES (High Power)
  ["basic_turret"] = {
    id = "basic_turret",
    name = "Basic Gun Turret",
    description = "A basic gun turret module.",
    category = "equipment",
    slot_type = "high_power",
    module_type = "active",
    effect = "fire_turret",
    energy_cost = 10,
    cooldown = 2,
    duration = 1,
    damage = {1, 3}, -- min, max
    value = 1000,
    stackable = false,
    maxStack = 1,
    color = {0.6, 0.6, 0.7, 1}, -- Greyish color
  },

  ["mining_laser"] = {
    id = "mining_laser",
    name = "Mining Laser I",
    description = "Extracts ore from asteroids.",
    category = "equipment",
    slot_type = "high_power",
    module_type = "active",
    effect = "mine_asteroid",
    energy_cost = 15,
    cooldown = 3,
    duration = 2,
    value = 1500,
    stackable = false,
    maxStack = 1,
    color = {0.9, 0.7, 0.2, 1}, -- Orangey-yellow
  },

  ["salvage_laser"] = {
    id = "salvage_laser",
    name = "Salvage Laser I",
    description = "Recovers materials from wreckage.",
    category = "equipment",
    slot_type = "high_power",
    module_type = "active",
    effect = "salvage_wreck",
    energy_cost = 20,
    cooldown = 4,
    duration = 3,
    value = 2000,
    stackable = false,
    maxStack = 1,
    color = {0.2, 0.9, 0.7, 1}, -- Teal
  },

  ["small_repairer"] = {
    id = "small_repairer",
    name = "Small Armor Repairer I",
    description = "Active armor repair system that restores hull integrity",
    category = "equipment",
    slot_type = "high_power",
    value = 550,
    stackable = false,
    maxStack = 1,
    color = {0.2, 0.8, 0.3, 1}, -- Green
    stats = {
      hp = 5
    }
  },

  -- MID POWER MODULES
  ["small_shield_booster"] = {
    id = "small_shield_booster",
    name = "Small Shield Booster I",
    description = "Increases shield capacity and regeneration",
    category = "equipment",
    slot_type = "mid_power",
    value = 400,
    stackable = false,
    maxStack = 1,
    color = {0.1, 0.5, 1, 1}, -- Blue
    stats = {
      maxShield = 15,
      shieldRegen = 5
    }
  },

  ["small_capacitor_booster"] = {
    id = "small_capacitor_booster",
    name = "Small Energy Booster I",
    description = "Increases energy capacity and regeneration rate",
    category = "equipment",
    slot_type = "mid_power",
    value = 350,
    stackable = false,
    maxStack = 1,
    color = {1, 1, 0.4, 1}, -- Yellow
    stats = {
      maxEnergy = 15,
      energyRegen = 3
    }
  },

  ["small_sensor_booster"] = {
    id = "small_sensor_booster",
    name = "Small Sensor Booster I",
    description = "Improves targeting accuracy and range",
    category = "equipment",
    slot_type = "mid_power",
    value = 300,
    stackable = false,
    maxStack = 1,
    color = {0.9, 0.6, 1, 1}, -- Light purple
  },

  ["small_afterburner"] = {
    id = "small_afterburner",
    name = "1MN Afterburner I",
    description = "Provides a speed boost at the cost of some maneuverability",
    category = "equipment",
    slot_type = "mid_power",
    value = 500,
    stackable = false,
    maxStack = 1,
    color = {0.8, 0.8, 0.5, 1}, -- Light yellow
    stats = {
      maxSpeed = 50,
      accel = 30
    }
  },

  -- LOW POWER MODULES
  ["heat_sink"] = {
    id = "heat_sink",
    name = "Heat Sink I",
    description = "Reduces weapon cooldown and increases damage output",
    category = "equipment",
    slot_type = "low_power",
    value = 250,
    stackable = false,
    maxStack = 1,
    color = {0.8, 0.4, 0.2, 1}, -- Brown-orange
  },

  ["co_processor"] = {
    id = "co_processor",
    name = "Co-Processor I",
    description = "Improves CPU performance and weapon accuracy",
    category = "equipment",
    slot_type = "low_power",
    value = 200,
    stackable = false,
    maxStack = 1,
    color = {0.4, 0.8, 0.6, 1}, -- Turquoise
  },

  ["adaptive_nano_plating"] = {
    id = "adaptive_nano_plating",
    name = "Adaptive Nano Plating I",
    description = "Provides additional hull integrity",
    category = "equipment",
    slot_type = "low_power",
    value = 300,
    stackable = false,
    maxStack = 1,
    color = {0.5, 0.5, 0.5, 1}, -- Gray
    stats = {
      maxHP = 10
    }
  },

  -- RIGS
  ["small_energy_burst_rig"] = {
    id = "small_energy_burst_rig",
    name = "Small Energy Burst Aerator I",
    description = "Rig that increases energy regeneration",
    category = "equipment",
    slot_type = "rig",
    value = 800,
    stackable = false,
    maxStack = 1,
    color = {1, 0.9, 0.3, 1}, -- Bright yellow
    stats = {
      energyRegen = 8
    }
  },

  ["small_armor_repairer_rig"] = {
    id = "small_armor_repairer_rig",
    name = "Small Auxiliary Nano Pump I",
    description = "Rig that increases hull repair effectiveness",
    category = "equipment",
    slot_type = "rig",
    value = 750,
    stackable = false,
    maxStack = 1,
    color = {0.3, 0.8, 0.4, 1}, -- Bright green
    stats = {
      hp = 8
    }
  },

  ["small_weapon_calibrator"] = {
    id = "small_weapon_calibrator",
    name = "Small Energy Burst Aerator I",
    description = "Rig that improves weapon performance",
    category = "equipment",
    slot_type = "rig",
    value = 850,
    stackable = false,
    maxStack = 1,
    color = {0.8, 0.3, 0.1, 1}, -- Bright orange
  }
}

-- Get item definition by ID
function M.get(itemId)
  return M.items[itemId]
end

-- Get all items in a category
function M.getByCategory(category)
  local result = {}
  for id, item in pairs(M.items) do
    if item.category == category then
      result[id] = item
    end
  end
  return result
end

-- Get item display name
function M.getName(itemId)
  local item = M.get(itemId)
  return item and item.name or itemId
end

-- Get item value
function M.getValue(itemId)
  local item = M.get(itemId)
  return item and item.value or 0
end

-- Get item color for display
function M.getColor(itemId)
  local item = M.get(itemId)
  return item and item.color or {1, 1, 1, 1}
end

-- Use/consume an item
function M.useItem(itemId, quantity)
  quantity = quantity or 1
  local item = M.get(itemId)
  if not item then return false, "Unknown item" end
  
  if item.effect then
    local message = item.effect(quantity)
    return true, message
  end
  
  return false, "Item cannot be used"
end

-- Check if item is stackable
function M.isStackable(itemId)
  local item = M.get(itemId)
  return item and item.stackable or false
end

-- Get max stack size
function M.getMaxStack(itemId)
  local item = M.get(itemId)
  return item and item.maxStack or 1
end

-- Generate random loot based on tier/difficulty
function M.generateRandomLoot(tier, bonusCredits)
  tier = tier or 1
  bonusCredits = bonusCredits or 0
  
  local loot = {}
  
  -- Always include credits
  loot.credits = math.floor((bonusCredits * (0.5 + love.math.random() * 0.5)) * 100) / 100
  
  -- Common drops based on tier
  local commonItems = {
    {id = "rockets", min = 5, max = 25, chance = 1.0},
    {id = "energy_cells", min = 10, max = 50, chance = 0.6},
    {id = "repair_kit", min = 1, max = 3, chance = 0.3},
    {id = "shield_booster", min = 1, max = 2, chance = 0.2},
    {id = "energy_drink", min = 1, max = 4, chance = 0.25}
  }
  
  -- Rare drops based on tier
  local rareItems = {
    {id = "alien_tech", min = 1, max = 2, chance = 0.1 + tier * 0.05},
    {id = "quantum_core", min = 1, max = 1, chance = 0.02 + tier * 0.01},
    {id = "neural_implant", min = 1, max = 1, chance = 0.01 + tier * 0.005}
  }
  
  -- Roll for common items
  for _, itemData in ipairs(commonItems) do
    if love.math.random() < itemData.chance then
      loot[itemData.id] = {
        quantity = math.floor(itemData.min + love.math.random() * (itemData.max - itemData.min))
      }
    end
  end
  
  -- Roll for rare items (higher tier = better chance)
  for _, itemData in ipairs(rareItems) do
    if love.math.random() < itemData.chance then
      loot[itemData.id] = {
        quantity = itemData.min
      }
    end
  end
  
  return loot
end


return M
