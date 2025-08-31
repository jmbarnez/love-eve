-- Minimal Sci-Fi HUD System
local ctx = require("src.core.ctx")
local credit = require("src.content.credit")
local loot_box = require("src.entities.loot_box")

local SimpleUI = {}
SimpleUI.inventoryOpen = false
SimpleUI.inventoryX = nil  -- Will be set when opened
SimpleUI.inventoryY = nil
SimpleUI.dragState = nil   -- {offsetX, offsetY}

-- Add container window variables
SimpleUI.containerOpen = false
SimpleUI.containerX = nil
SimpleUI.containerY = nil
SimpleUI.containerDragState = nil

-- Minimal sci-fi theme
local theme = {
    primary = {0.0, 0.8, 1.0},      -- Cyan
    warning = {1.0, 0.3, 0.2},      -- Red  
    energy = {0.2, 1.0, 0.4},       -- Green
    xp = {1.0, 0.8, 0.2},           -- Gold
    
    bg = {0.05, 0.1, 0.15, 0.85},   -- Dark blue background
    border = {0.2, 0.4, 0.6, 0.9},  -- Blue border
    text = {0.9, 0.95, 1.0, 1.0},   -- Light blue text
}

function SimpleUI.init()
    print("Minimal Sci-Fi HUD: Initializing...")
    SimpleUI.enabled = true
    print("Minimal Sci-Fi HUD: Initialized successfully")
end

function SimpleUI.update(dt)
    if not SimpleUI.enabled then return end
    
    -- Handle dragging for inventory
    if SimpleUI.dragState then
        local mx, my = love.mouse.getPosition()
        SimpleUI.inventoryX = mx - SimpleUI.dragState.offsetX
        SimpleUI.inventoryY = my - SimpleUI.dragState.offsetY
        
        -- Keep window on screen
        local W, H = love.graphics.getWidth(), love.graphics.getHeight()
        local invW, invH = 600, 400
        SimpleUI.inventoryX = math.max(0, math.min(SimpleUI.inventoryX, W - invW))
        SimpleUI.inventoryY = math.max(0, math.min(SimpleUI.inventoryY, H - invH))
    end

    -- Handle dragging for container
    if SimpleUI.containerDragState then
        local mx, my = love.mouse.getPosition()
        SimpleUI.containerX = mx - SimpleUI.containerDragState.offsetX
        SimpleUI.containerY = my - SimpleUI.containerDragState.offsetY
        
        -- Keep window on screen
        local W, H = love.graphics.getWidth(), love.graphics.getHeight()
        local contW, contH = 600, 400
        SimpleUI.containerX = math.max(0, math.min(SimpleUI.containerX, W - contW))
        SimpleUI.containerY = math.max(0, math.min(SimpleUI.containerY, H - contH))
    end
end

-- Draw a compact status bar (no labels)
local function drawCompactBar(x, y, w, h, value, maxValue, color)
    local pct = math.max(0, math.min(1, value / maxValue))
    
    -- Background
    love.graphics.setColor(theme.bg)
    love.graphics.rectangle("fill", x, y, w, h, 2)
    
    -- Fill bar with gradient effect
    love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.6)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)
    
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * pct, h - 2, 1)
    
    -- Inner glow
    if pct > 0 then
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", x + 2, y + 2, math.max(1, (w - 4) * pct), 1)
    end
    
    -- Border
    love.graphics.setColor(theme.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 2)
    
    -- Just percentage text, small
    local font = love.graphics.getFont()
    love.graphics.setColor(1, 1, 1, 0.8)
    local text = string.format("%.0f%%", pct * 100)
    local textW = font:getWidth(text)
    if textW < w - 4 then
        love.graphics.printf(text, x, y + 1, w, "center")
    end
end

-- Draw target bar with labels
local function drawTargetBar(x, y, w, h, value, maxValue, color, label)
    local pct = math.max(0, math.min(1, value / maxValue))
    
    -- Background
    love.graphics.setColor(theme.bg)
    love.graphics.rectangle("fill", x, y, w, h, 2)
    
    -- Fill
    love.graphics.setColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.6)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 1)
    
    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", x + 1, y + 1, (w - 2) * pct, h - 2, 1)
    
    -- Border
    love.graphics.setColor(theme.border)
    love.graphics.rectangle("line", x, y, w, h, 2)
    
    -- Label above bar (removed)
    -- if label and label ~= "" then
    --     love.graphics.setColor(theme.text)
    --     love.graphics.printf(label, x, y - 14, w, "left")
    -- end
    
    -- Values (changed to centered percentage)
    love.graphics.setColor(1, 1, 1, 0.9)
    local text = string.format("%.0f%%", pct * 100)
    love.graphics.printf(text, x, y + 1, w, "center")
end

function SimpleUI.draw()
    if not SimpleUI.enabled or not ctx.player then return end
    
    love.graphics.push()
    love.graphics.origin()
    
    local W, H = love.graphics.getWidth(), love.graphics.getHeight()
    local p = ctx.player
    
    -- PLAYER STATUS - TOP LEFT (compact, no labels)
    local statusX, statusY = 20, 20
    local statusW, statusH = 180, 14
    local spacing = 16
    
    -- Compact status bars
    drawCompactBar(statusX, statusY, statusW, statusH, p.hp, p.maxHP, theme.warning)              -- Hull (red)
    drawCompactBar(statusX, statusY + spacing, statusW, statusH, p.shield, p.maxShield, theme.primary)  -- Shield (cyan)
    drawCompactBar(statusX, statusY + spacing * 2, statusW, statusH, p.energy, p.maxEnergy, theme.energy) -- Energy (green)
    -- Removed XP bar
    -- drawCompactBar(statusX, statusY + spacing * 3, statusW, 10, p.xp, p.xpToNext, theme.xp)      -- XP (gold, thinner)
    
    -- Level and credits (small, below status bars) (removed level and credits)
    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
    -- Removed level text
    -- love.graphics.printf(string.format("LV%d", p.level), statusX, statusY + spacing * 4, 60, "left")
    
    -- Removed credit icon and value
    -- credit.draw(statusX + 70, statusY + spacing * 4 - 2, 12)
    -- love.graphics.printf(string.format("%.2f", p.credits), statusX + 70 + 16, statusY + spacing * 4, 120, "left")
    
    
    -- Fixed-size minimap (top right)
    local mapSize = 120
    local mapX, mapY = W - mapSize - 20, 20
    
    -- Map background
    love.graphics.setColor(theme.bg)
    love.graphics.rectangle("fill", mapX, mapY, mapSize, mapSize, 4)
    love.graphics.setColor(theme.border)
    love.graphics.rectangle("line", mapX, mapY, mapSize, mapSize, 4)
    
    -- Grid
    love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.3)
    for i = 1, 3 do
        local gx = mapX + (mapSize / 4) * i
        local gy = mapY + (mapSize / 4) * i  
        love.graphics.line(gx, mapY, gx, mapY + mapSize)
        love.graphics.line(mapX, gy, mapX + mapSize, gy)
    end
    
    -- Map entities
    local half = ctx.G.WORLD_SIZE
    local function toMini(wx, wy)
        local u = (wx + half) / (2 * half)
        local v = (wy + half) / (2 * half)
        return mapX + u * mapSize, mapY + v * mapSize
    end
    
    -- Station
    if ctx.station then
        local sx, sy = toMini(ctx.station.x, ctx.station.y)
        love.graphics.setColor(theme.energy)
        love.graphics.circle("fill", sx, sy, 3)
    end
    
    -- Enemies
    love.graphics.setColor(theme.warning)
    for _, e in ipairs(ctx.enemies or {}) do
        local ex, ey = toMini(e.x, e.y)
        love.graphics.rectangle("fill", ex - 1, ey - 1, 2, 2)
    end
    
    -- Player
    local px, py = toMini(p.x, p.y)
    love.graphics.setColor(theme.primary)
    love.graphics.circle("fill", px, py, 3)
    
    -- EVE-STYLE INVENTORY PANEL (Tab to open/close)
    if SimpleUI.inventoryOpen then
        local invW, invH = 600, 400
        
        -- Initialize position if not set (first time opening)
        if not SimpleUI.inventoryX or not SimpleUI.inventoryY then
            SimpleUI.inventoryX = (W - invW) / 2
            SimpleUI.inventoryY = (H - invH) / 2
        end
        
        local invX = SimpleUI.inventoryX
        local invY = SimpleUI.inventoryY
        
        -- Main window background
        love.graphics.setColor(0.02, 0.05, 0.08, 0.98)
        love.graphics.rectangle("fill", invX, invY, invW, invH, 4)
        
        -- Window border
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", invX, invY, invW, invH, 4)
        
        -- Title bar
        love.graphics.setColor(0.08, 0.15, 0.22, 1)
        love.graphics.rectangle("fill", invX, invY, invW, 30, 4)
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
        love.graphics.line(invX, invY + 30, invX + invW, invY + 30)
        
        -- Title text
        love.graphics.setColor(theme.text)
        love.graphics.printf("INVENTORY", invX + 10, invY + 8, invW - 20, "left")
        
        -- Close button (X)
        love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
        love.graphics.rectangle("fill", invX + invW - 25, invY + 5, 20, 20, 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("×", invX + invW - 25, invY + 5, 20, "center")
        
        -- MAIN INVENTORY AREA (Full width, no sidebar)
        local mainX = invX + 1
        local mainY = invY + 30
        local mainW = invW - 1
        local mainH = invH - 30
        
        -- Display inventory items in Windows-style grid
        local gridStartY = mainY
        local player = require("src.entities.player")
        local inventory = ctx.player.inventory or {}
        
        -- Grid settings
        local itemSize = 64
        local itemSpacing = 8
        local itemsPerRow = math.floor((mainW - 20) / (itemSize + itemSpacing))
        local mx, my = love.mouse.getPosition()
        
        -- Collect items with quantities > 0
        local items = {}
        for itemType, quantity in pairs(inventory) do
            if quantity > 0 then
                table.insert(items, {type = itemType, quantity = quantity})
            end
        end
        
        -- Display items in grid
        for i, item in ipairs(items) do
            local row = math.floor((i - 1) / itemsPerRow)
            local col = (i - 1) % itemsPerRow
            local itemX = mainX + 10 + col * (itemSize + itemSpacing)
            local itemY = gridStartY + row * (itemSize + itemSpacing + 20) -- Extra space for name
            
            -- Check if mouse is hovering over this item
            local isHovered = mx >= itemX and mx <= itemX + itemSize and 
                            my >= itemY and my <= itemY + itemSize and
                            SimpleUI.inventoryOpen
            
            -- Item slot background
            if isHovered then
                love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.3)
            else
                love.graphics.setColor(0.06, 0.12, 0.18, 0.8)
            end
            love.graphics.rectangle("fill", itemX, itemY, itemSize, itemSize, 4)
            
            -- Item slot border
            if isHovered then
                love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.8)
            else
                love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
            end
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", itemX, itemY, itemSize, itemSize, 4)
            
            -- Draw item icon
            SimpleUI.drawItemIcon(item.type, itemX + itemSize/2, itemY + itemSize/2, itemSize * 0.6)
            
            -- Item quantity in bottom right
            love.graphics.setColor(1, 1, 1, 0.9)
            local qtyText = tostring(item.quantity)
            local qtyFont = love.graphics.getFont()
            local qtyW = qtyFont:getWidth(qtyText)
            local qtyH = qtyFont:getHeight()
            love.graphics.printf(qtyText, itemX + itemSize - qtyW - 4, itemY + itemSize - qtyH - 2, qtyW, "left")
            
            -- Item name below icon
            local itemName = SimpleUI.getItemDisplayName(item.type)
            love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
            love.graphics.printf(itemName, itemX, itemY + itemSize + 2, itemSize, "center")
            
            -- Tooltip on hover
            if isHovered then
                SimpleUI.drawTooltip(item.type, item.quantity, mx + 15, my - 10)
            end
        end
        
        -- If no items, show empty message
        if #items == 0 then
            local emptyY = gridStartY + 100
            love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.4)
            love.graphics.printf("Cargo hold is empty", mainX, emptyY, mainW, "center")
            love.graphics.printf("Items will appear here when collected", mainX, emptyY + 20, mainW, "center")
        end
        
        -- Status bar at bottom
        love.graphics.setColor(0.04, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", invX, invY + invH - 25, invW, 25)
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.4)
        love.graphics.line(invX, invY + invH - 25, invX + invW, invY + invH - 25)
        
        love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
        
        -- Draw credit icon
        credit.draw(invX + 10, invY + invH - 18 - 2, 12)
        
        love.graphics.printf(string.format("Credits: %s", p.credits >= 1000000 and string.format("%.1fM", p.credits/1000000) or string.format("%.2f", p.credits)), 
                           invX + 10 + 16, invY + invH - 18, 200, "left")
        love.graphics.printf(string.format("%d items", SimpleUI.getTotalInventoryItems()), invX, invY + invH - 18, invW - 10, "right")
    end
    
    -- CONTAINER WINDOW (similar to inventory)
    if ctx.containerOpen and ctx.currentContainer then
        local contW, contH = 600, 400
        
        -- Initialize position if not set (first time opening)
        if not SimpleUI.containerX or not SimpleUI.containerY then
            SimpleUI.containerX = (W - contW) / 2
            SimpleUI.containerY = (H - contH) / 2
        end
        
        local contX = SimpleUI.containerX
        local contY = SimpleUI.containerY
        
        -- Main window background
        love.graphics.setColor(0.02, 0.05, 0.08, 0.98)
        love.graphics.rectangle("fill", contX, contY, contW, contH, 4)
        
        -- Window border
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", contX, contY, contW, contH, 4)
        
        -- Title bar
        love.graphics.setColor(0.08, 0.15, 0.22, 1)
        love.graphics.rectangle("fill", contX, contY, contW, 30, 4)
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
        love.graphics.line(contX, contY + 30, contX + contW, contY + 30)
        
        -- Title text
        love.graphics.setColor(theme.text)
        love.graphics.printf("CONTAINER", contX + 10, contY + 8, contW - 20, "left")
        
        -- Close button (X)
        love.graphics.setColor(theme.warning[1], theme.warning[2], theme.warning[3], 0.8)
        love.graphics.rectangle("fill", contX + contW - 25, contY + 5, 20, 20, 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("×", contX + contW - 25, contY + 5, 20, "center")
        
        -- MAIN CONTAINER AREA (Full width, no sidebar)
        local mainX = contX + 1
        local mainY = contY + 30
        local mainW = contW - 1
        local mainH = contH - 30
        
        -- Display container items in grid
        local gridStartY = mainY
        local containerContents = ctx.currentContainer.contents or {}
        
        -- Grid settings
        local itemSize = 64
        local itemSpacing = 8
        local itemsPerRow = math.floor((mainW - 20) / (itemSize + itemSpacing))
        local mx, my = love.mouse.getPosition()
        
        -- Collect items with quantities > 0
        local items = {}
        for itemType, data in pairs(containerContents) do
            local quantity, name
            if type(data) == "table" then
                quantity = data.quantity
                name = data.name or itemType
            elseif type(data) == "number" then
                quantity = data
                name = itemType  -- e.g., "credits"
            end
            if quantity and quantity > 0 then
                table.insert(items, {type = itemType, quantity = quantity, name = name})
            end
        end
        
        -- Display items in grid
        for i, item in ipairs(items) do
            local row = math.floor((i - 1) / itemsPerRow)
            local col = (i - 1) % itemsPerRow
            local itemX = mainX + 10 + col * (itemSize + itemSpacing)
            local itemY = gridStartY + row * (itemSize + itemSpacing + 20)
            
            -- Check if mouse is hovering over this item
            local isHovered = mx >= itemX and mx <= itemX + itemSize and 
                            my >= itemY and my <= itemY + itemSize and
                            ctx.containerOpen
            
            -- Item slot background
            if isHovered then
                love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.3)
            else
                love.graphics.setColor(0.06, 0.12, 0.18, 0.8)
            end
            love.graphics.rectangle("fill", itemX, itemY, itemSize, itemSize, 4)
            
            -- Item slot border
            if isHovered then
                love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.8)
            else
                love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.6)
            end
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", itemX, itemY, itemSize, itemSize, 4)
            
            -- Draw item icon
            SimpleUI.drawItemIcon(item.type, itemX + itemSize/2, itemY + itemSize/2, itemSize * 0.6)
            
            -- Item quantity in bottom right
            love.graphics.setColor(1, 1, 1, 0.9)
            local qtyText = tostring(item.quantity)
            local qtyFont = love.graphics.getFont()
            local qtyW = qtyFont:getWidth(qtyText)
            local qtyH = qtyFont:getHeight()
            love.graphics.printf(qtyText, itemX + itemSize - qtyW - 4, itemY + itemSize - qtyH - 2, qtyW, "left")
            
            -- Item name below icon
            love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
            love.graphics.printf(item.name, itemX, itemY + itemSize + 2, itemSize, "center")
            
            -- Tooltip on hover
            if isHovered then
                SimpleUI.drawTooltip(item.type, item.quantity, mx + 15, my - 10)
            end
        end
        
        -- If no items, show empty message
        if #items == 0 then
            local emptyY = gridStartY + 100
            love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.4)
            love.graphics.printf("Container is empty", mainX, emptyY, mainW, "center")
        end
        
        -- Take All button
        if #items > 0 then
            local buttonW = 100
            local buttonH = 30
            local buttonX = mainX + 10
            local buttonY = mainY + mainH - buttonH - 30
            love.graphics.setColor(0.1, 0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", buttonX, buttonY, buttonW, buttonH, 4)
            love.graphics.setColor(theme.border)
            love.graphics.rectangle("line", buttonX, buttonY, buttonW, buttonH, 4)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("Take All", buttonX, buttonY + 5, buttonW, "center")
        end
        
        -- Status bar at bottom
        love.graphics.setColor(0.04, 0.08, 0.12, 1)
        love.graphics.rectangle("fill", contX, contY + contH - 25, contW, 25)
        love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.4)
        love.graphics.line(contX, contY + contH - 25, contX + contW, contY + contH - 25)
        
        love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.8)
        love.graphics.printf(string.format("%d items", #items), contX, contY + contH - 18, contW - 10, "right")
    end
    
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
    love.graphics.pop()
end

function SimpleUI.getTotalInventoryItems()
    local player = require("src.entities.player")
    local total = 0
    for itemType, quantity in pairs(ctx.player.inventory or {}) do
        total = total + quantity
    end
    return total
end

function SimpleUI.getItemDisplayName(itemType)
    local items = require("src.content.items")
    return items.getName(itemType)
end

function SimpleUI.drawItemIcon(itemType, x, y, size)
    local items = require("src.content.items")
    local color = items.getColor(itemType)
    
    love.graphics.push()
    love.graphics.translate(x, y)
    
    if itemType == "rockets" then
        -- Rocket icon (triangle with flame)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.polygon("fill", 0, -size/2, -size/3, size/2, size/3, size/2)
        love.graphics.setColor(1, 0.5, 0, 1) -- Orange flame
        love.graphics.polygon("fill", -size/6, size/2, 0, size/2 + size/4, size/6, size/2)
    elseif itemType == "energy_cells" then
        -- Energy cell icon (battery shape)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", -size/3, -size/2, size/3, size)
        love.graphics.rectangle("fill", -size/6, -size/2 - size/8, size/6, size/8) -- Terminal
        love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4])
        love.graphics.rectangle("fill", -size/4, -size/3, size/4, size/3) -- Charge level
    elseif itemType == "alien_tech" then
        -- Alien tech icon (circuit-like)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.circle("fill", 0, 0, size/3)
        love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4])
        love.graphics.circle("fill", -size/4, -size/4, size/6)
        love.graphics.circle("fill", size/4, -size/4, size/6)
        love.graphics.circle("fill", 0, size/4, size/6)
        -- Connections
        love.graphics.setLineWidth(2)
        love.graphics.line(-size/4, -size/4, size/4, -size/4)
        love.graphics.line(0, -size/4, 0, size/4)
    elseif itemType == "repair_kit" then
        -- Repair kit icon (medical cross)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", -size/8, -size/2, size/4, size)
        love.graphics.rectangle("fill", -size/2, -size/8, size, size/4)
    elseif itemType == "shield_booster" then
        -- Shield booster icon (shield shape)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.polygon("fill", 0, -size/2, -size/3, -size/4, -size/3, size/3, 0, size/2, size/3, size/3, size/3, -size/4)
    elseif itemType == "energy_drink" then
        -- Energy drink icon (bottle)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", -size/6, -size/2, size/3, size * 0.8)
        love.graphics.rectangle("fill", -size/8, -size/2 - size/8, size/4, size/8) -- Cap
    elseif itemType == "quantum_core" then
        -- Quantum core icon (pulsing orb)
        local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 4)
        love.graphics.setColor(color[1], color[2], color[3], color[4] * pulse)
        love.graphics.circle("fill", 0, 0, size/3 * pulse)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("line", 0, 0, size/2)
    elseif itemType == "neural_implant" then
        -- Neural implant icon (brain-like)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.circle("fill", -size/6, -size/6, size/4)
        love.graphics.circle("fill", size/6, -size/6, size/4)
        love.graphics.rectangle("fill", -size/4, 0, size/2, size/3)
    else
        -- Default icon (box with item color)
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.rectangle("fill", -size/2, -size/2, size, size)
        love.graphics.setColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, color[4])
        love.graphics.rectangle("line", -size/2, -size/2, size, size)
    end
    
    love.graphics.pop()
end

function SimpleUI.drawTooltip(itemType, quantity, x, y)
    local items = require("src.content.items")
    local itemDef = items.get(itemType)
    local itemName = SimpleUI.getItemDisplayName(itemType)
    
    local tooltipText = itemName .. "\nQuantity: " .. quantity
    if itemDef and itemDef.description then
        tooltipText = tooltipText .. "\n" .. itemDef.description
    end
    if itemDef and itemDef.value then
        tooltipText = tooltipText .. "\nValue: " .. itemDef.value .. " credits each"
    end
    
    -- Measure text
    local font = love.graphics.getFont()
    local lines = {}
    for line in tooltipText:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, font:getWidth(line))
    end
    
    local lineHeight = font:getHeight()
    local tooltipW = maxWidth + 20
    local tooltipH = #lines * lineHeight + 10
    
    -- Tooltip background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", x, y, tooltipW, tooltipH, 4)
    
    -- Tooltip border
    love.graphics.setColor(theme.border[1], theme.border[2], theme.border[3], 0.8)
    love.graphics.rectangle("line", x, y, tooltipW, tooltipH, 4)
    
    -- Tooltip text
    love.graphics.setColor(1, 1, 1, 1)
    for i, line in ipairs(lines) do
        love.graphics.printf(line, x + 10, y + 5 + (i-1) * lineHeight, tooltipW - 20, "left")
    end
end

function SimpleUI.mousepressed(x, y, button)
    if button ~= 1 then return false end
    
    -- Handle inventory window
    if SimpleUI.inventoryOpen then
        local invW, invH = 600, 400
        local invX = SimpleUI.inventoryX or 0
        local invY = SimpleUI.inventoryY or 0
        
        -- Check if clicking on title bar (draggable area)
        if x >= invX and x <= invX + invW and y >= invY and y <= invY + 30 then
            -- Check if clicking close button
            if x >= invX + invW - 25 and x <= invX + invW - 5 and y >= invY + 5 and y <= invY + 25 then
                SimpleUI.inventoryOpen = false
                return true
            end
            
            -- Start dragging
            SimpleUI.dragState = {
                offsetX = x - invX,
                offsetY = y - invY
            }
            return true
        end
        
        -- Check if clicking inside window (to prevent clicking through)
        if x >= invX and x <= invX + invW and y >= invY and y <= invY + invH then
            return true -- Consume click to prevent world interaction
        end
    end
    
    -- Handle container window
    if ctx.containerOpen then
        local contW, contH = 600, 400
        local contX = SimpleUI.containerX or 0
        local contY = SimpleUI.containerY or 0
        
        -- Check if clicking on title bar (draggable area)
        if x >= contX and x <= contX + contW and y >= contY and y <= contY + 30 then
            -- Check if clicking close button
            if x >= contX + contW - 25 and x <= contX + contW - 5 and y >= contY + 5 and y <= contY + 25 then
                ctx.containerOpen = false
                ctx.currentContainer = nil
                -- Remove the container from lootBoxes
                for i, box in ipairs(ctx.lootBoxes) do
                    if box == ctx.currentContainer then
                        table.remove(ctx.lootBoxes, i)
                        break
                    end
                end
                return true
            end
            
            -- Start dragging
            SimpleUI.containerDragState = {
                offsetX = x - contX,
                offsetY = y - contY
            }
            return true
        end
        
        -- Check if clicking on an item to take it
        local containerContents = ctx.currentContainer.contents or {}
        local itemSize = 64
        local itemSpacing = 8
        local itemsPerRow = math.floor((contW - 20) / (itemSize + itemSpacing))
        local mainX = contX + 1
        local mainY = contY + 30
        local mainH = contH - 30
        local gridStartY = mainY
        
        local items = {}
        for itemType, data in pairs(containerContents) do
            local quantity, name
            if type(data) == "table" then
                quantity = data.quantity
                name = data.name or itemType
            elseif type(data) == "number" then
                quantity = data
                name = "Credits"
            end
            if quantity and quantity > 0 then
                table.insert(items, {type = itemType, quantity = quantity, name = name})
            end
        end
        
        for i, item in ipairs(items) do
            local row = math.floor((i - 1) / itemsPerRow)
            local col = (i - 1) % itemsPerRow
            local itemX = mainX + 10 + col * (itemSize + itemSpacing)
            local itemY = gridStartY + row * (itemSize + itemSpacing + 20)
            
            if x >= itemX and x <= itemX + itemSize and y >= itemY and y <= itemY + itemSize then
                -- Take the item
                if item.type == "credits" then
                    ctx.player.credits = ctx.player.credits + item.quantity
                else
                    local player = require("src.entities.player")
                    player.addToInventory(item.type, item.quantity)
                end
                containerContents[item.type] = nil  -- Remove from container
                loot_box.showNotification("+" .. item.quantity .. " " .. item.name, {0, 1, 0, 1})
                return true
            end
        end
        
        -- Check take all button
        if #items > 0 then
            local buttonW = 100
            local buttonH = 30
            local buttonX = mainX + 10
            local buttonY = mainY + mainH - buttonH - 30
            if x >= buttonX and x <= buttonX + buttonW and y >= buttonY and y <= buttonY + buttonH then
                -- Take all items
                for _, item in ipairs(items) do
                    if item.type == "credits" then
                        ctx.player.credits = ctx.player.credits + item.quantity
                    else
                        local player = require("src.entities.player")
                        player.addToInventory(item.type, item.quantity)
                    end
                    containerContents[item.type] = nil
                end
                loot_box.showNotification("Took all items", {0, 1, 0, 1})
                
                -- Close container panel and remove from world
                ctx.containerOpen = false
                if ctx.currentContainer then
                    for i, box in ipairs(ctx.lootBoxes) do
                        if box == ctx.currentContainer then
                            table.remove(ctx.lootBoxes, i)
                            break
                        end
                    end
                    ctx.currentContainer = nil
                end
                
                return true
            end
        end
        
        -- Check if clicking inside window (to prevent clicking through)
        if x >= contX and x <= contX + contW and y >= contY and y <= contY + contH then
            return true -- Consume click to prevent world interaction
        end
    end
    
    return false
end

function SimpleUI.mousereleased(x, y, button)
    if button == 1 and SimpleUI.dragState then
        SimpleUI.dragState = nil
        return true
    end
    return false
end

function SimpleUI.keypressed(key)
    if key == "tab" then
        SimpleUI.inventoryOpen = not SimpleUI.inventoryOpen
        return true -- Consume the key press
    end
    return false
end

return SimpleUI