-- In-game Debug Console Panel
-- Scrollable debug console with proper UI styling

local theme = require("src.ui.theme")

local M = {}

local debug_messages = {}
local max_messages = 100 -- Keep more messages for scrolling
local scroll_offset = 0
local panel_height = 300
local panel_width = 500
local visible_lines = 0
local ui_scale = 1.0

-- Panel state
local panel = {
    x = 0,
    y = 0,
    width = 0, -- Will be calculated
    height = 0, -- Will be calculated
    title = "Debug Console",
    visible = false,
    dragging = false,
    drag_offset_x = 0,
    drag_offset_y = 0,
    selecting = false,
    selection_start = 0,
    selection_end = 0,
    focused = false
}

-- Add a debug message
function M.log(message)
    table.insert(debug_messages, {
        text = tostring(message),
        time = love.timer.getTime()
    })
    
    -- Keep only the most recent messages
    while #debug_messages > max_messages do
        table.remove(debug_messages, 1)
    end
    
    -- Auto-scroll to bottom when new message arrives
    local font = love.graphics.getFont()
    local font_height = font:getHeight()
    local line_spacing = 2 * ui_scale
    local content_height = panel.height - (40 * ui_scale) -- Account for title bar
    visible_lines = math.floor(content_height / (font_height + line_spacing))
    
    if #debug_messages > visible_lines then
        scroll_offset = #debug_messages - visible_lines
    end
end

-- Toggle panel visibility
function M.toggle()
    panel.visible = not panel.visible
end

-- Get all text as string for copying
function M.getAllText()
    local text = ""
    for i, msg in ipairs(debug_messages) do
        text = text .. msg.text
        if i < #debug_messages then
            text = text .. "\n"
        end
    end
    return text
end

-- Get selected text
function M.getSelectedText()
    if panel.selection_start == panel.selection_end then
        return ""
    end
    
    local start_line = math.min(panel.selection_start, panel.selection_end)
    local end_line = math.max(panel.selection_start, panel.selection_end)
    
    local text = ""
    for i = start_line, end_line do
        if debug_messages[i] then
            text = text .. debug_messages[i].text
            if i < end_line then
                text = text .. "\n"
            end
        end
    end
    return text
end

-- Copy to clipboard
function M.copyToClipboard()
    local text = ""
    if panel.selection_start ~= panel.selection_end then
        text = M.getSelectedText()
    else
        text = M.getAllText()
    end
    
    if text ~= "" then
        love.system.setClipboardText(text)
        M.log("CONSOLE: Copied " .. (panel.selection_start ~= panel.selection_end and "selection" or "all text") .. " to clipboard")
    end
end

-- Select all text
function M.selectAll()
    panel.selection_start = 1
    panel.selection_end = #debug_messages
end

-- Clear selection
function M.clearSelection()
    panel.selection_start = 0
    panel.selection_end = 0
end

-- Handle keyboard input
function M.keypressed(key)
    if not panel.visible or not panel.focused then return false end
    
    if love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl") then
        if key == "a" then
            M.selectAll()
            return true
        elseif key == "c" then
            M.copyToClipboard()
            return true
        end
    end
    
    -- Keyboard scrolling
    if key == "up" then
        scroll_offset = math.max(0, scroll_offset - 1)
        return true
    elseif key == "down" then
        local max_scroll = math.max(0, #debug_messages - visible_lines)
        scroll_offset = math.min(max_scroll, scroll_offset + 1)
        return true
    elseif key == "pageup" then
        scroll_offset = math.max(0, scroll_offset - visible_lines)
        return true
    elseif key == "pagedown" then
        local max_scroll = math.max(0, #debug_messages - visible_lines)
        scroll_offset = math.min(max_scroll, scroll_offset + visible_lines)
        return true
    elseif key == "home" then
        scroll_offset = 0
        return true
    elseif key == "end" then
        scroll_offset = math.max(0, #debug_messages - visible_lines)
        return true
    elseif key == "escape" then
        M.clearSelection()
        return true
    end
    
    return false
end

-- Handle mouse wheel scrolling
function M.mousewheelmoved(x, y)
    if not panel.visible then return end
    
    -- Only scroll if mouse is over the panel
    local mx, my = love.mouse.getPosition()
    if mx >= panel.x and mx <= panel.x + panel.width and 
       my >= panel.y and my <= panel.y + panel.height then
        if y > 0 then
            -- Scroll up
            scroll_offset = math.max(0, scroll_offset - 3)
        elseif y < 0 then
            -- Scroll down
            local max_scroll = math.max(0, #debug_messages - visible_lines)
            scroll_offset = math.min(max_scroll, scroll_offset + 3)
        end
        return true -- Consume the event
    end
    return false
end

-- Handle mouse pressed
function M.mousepressed(x, y, button)
    if not panel.visible then return false end
    
    -- Check if clicking anywhere on the panel
    if x >= panel.x and x <= panel.x + panel.width and
       y >= panel.y and y <= panel.y + panel.height then
        panel.focused = true
        
        local title_height = 25 * ui_scale
        -- Check if clicking on title bar for dragging
        if y >= panel.y and y <= panel.y + title_height then
            if button == 1 then
                panel.dragging = true
                panel.drag_offset_x = x - panel.x
                panel.drag_offset_y = y - panel.y
                return true
            end
        else
            -- Clicking in content area
            if button == 1 then
                -- Start text selection
                local content_y = panel.y + title_height + (5 * ui_scale)
                local font_height = love.graphics.getFont():getHeight()
                local line_spacing = 2 * ui_scale
                local line_height = font_height + line_spacing
                
                local relative_y = y - content_y
                local clicked_line = math.floor(relative_y / line_height) + scroll_offset + 1
                
                panel.selecting = true
                panel.selection_start = math.max(1, math.min(#debug_messages, clicked_line))
                panel.selection_end = panel.selection_start
                return true
            end
        end
        return true -- Consume the event
    else
        panel.focused = false
        panel.selecting = false
    end
    
    return false
end

-- Handle mouse released
function M.mousereleased(x, y, button)
    if button == 1 then
        panel.dragging = false
        panel.selecting = false
    end
end

-- Handle mouse moved
function M.mousemoved(x, y, dx, dy)
    if panel.dragging then
        panel.x = x - panel.drag_offset_x
        panel.y = y - panel.drag_offset_y
        
        -- Keep panel on screen
        local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
        panel.x = math.max(0, math.min(screen_w - panel.width, panel.x))
        panel.y = math.max(0, math.min(screen_h - panel.height, panel.y))
    elseif panel.selecting and love.mouse.isDown(1) then
        -- Update selection
        local title_height = 25 * ui_scale
        local content_y = panel.y + title_height + (5 * ui_scale)
        local font_height = love.graphics.getFont():getHeight()
        local line_spacing = 2 * ui_scale
        local line_height = font_height + line_spacing
        
        local relative_y = y - content_y
        local current_line = math.floor(relative_y / line_height) + scroll_offset + 1
        
        panel.selection_end = math.max(1, math.min(#debug_messages, current_line))
    end
end

-- Update
function M.update(dt)
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    panel.width = screen_w
    panel.height = screen_h / 2
    panel.x = 0
    panel.y = 0
end

-- Draw the debug console panel
function M.draw()
    if not panel.visible then return end
    
    local font = love.graphics.getFont()
    local font_height = font:getHeight()
    local line_spacing = 2 * ui_scale
    local title_height = 25 * ui_scale
    
    -- Calculate visible lines
    local content_height = panel.height - title_height - (10 * ui_scale)
    visible_lines = math.floor(content_height / (font_height + line_spacing))
    
    -- Panel background (dark with sci-fi styling)
    love.graphics.setColor(0.05, 0.05, 0.1, 0.8)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height)
    
    -- Panel border (blue accent)
    love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height)
    
    -- Title bar background
    love.graphics.setColor(0.1, 0.15, 0.25, 0.8)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, title_height)
    
    -- Title bar border
    love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(panel.x, panel.y + title_height, panel.x + panel.width, panel.y + title_height)
    
    -- Title text
    love.graphics.setColor(theme.text)
    love.graphics.printf(panel.title, panel.x + (10 * ui_scale), panel.y + (6 * ui_scale), panel.width - (20 * ui_scale), "left")
    
    -- Message count indicator
    local msg_count_text = #debug_messages .. " messages"
    love.graphics.setColor(theme.text[1], theme.text[2], theme.text[3], 0.7)
    love.graphics.printf(msg_count_text, panel.x + (10 * ui_scale), panel.y + (6 * ui_scale), panel.width - (20 * ui_scale), "right")
    
    -- Content area clipping
    local content_x = panel.x + (8 * ui_scale)
    local content_y = panel.y + title_height + (5 * ui_scale)
    local content_w = panel.width - (16 * ui_scale)
    local content_h = content_height
    
    -- Set scissor for scrolling content
    love.graphics.setScissor(content_x, content_y, content_w, content_h)
    
    -- Draw messages
    local start_index = math.max(1, scroll_offset + 1)
    local end_index = math.min(#debug_messages, start_index + visible_lines - 1)
    
    local text_y = content_y
    local line_height = font_height + line_spacing
    
    -- Draw selection background first
    if panel.selection_start ~= panel.selection_end then
        local sel_start = math.min(panel.selection_start, panel.selection_end)
        local sel_end = math.max(panel.selection_start, panel.selection_end)
        
        for i = start_index, end_index do
            if i >= sel_start and i <= sel_end then
                local line_y = content_y + (i - start_index) * line_height
                love.graphics.setColor(0.3, 0.5, 0.8, 0.4) -- Blue selection background
                love.graphics.rectangle("fill", content_x, line_y, content_w - (16 * ui_scale), font_height)
            end
        end
    end
    
    -- Draw message text
    for i = start_index, end_index do
        local msg = debug_messages[i]
        local age = love.timer.getTime() - msg.time
        local line_y = content_y + (i - start_index) * line_height
        
        -- Color based on age (newer messages are brighter)
        local alpha = math.max(0.4, 1 - (age / 30)) -- Fade over 30 seconds
        
        -- Highlight selected text
        local is_selected = (panel.selection_start ~= panel.selection_end and 
                           i >= math.min(panel.selection_start, panel.selection_end) and 
                           i <= math.max(panel.selection_start, panel.selection_end))
        
        if is_selected then
            love.graphics.setColor(1, 1, 1, 1) -- Full brightness for selected text
        else
            love.graphics.setColor(0.9, 0.9, 0.9, alpha)
        end
        
        -- Wrap long messages
        local wrapped_text = msg.text
        local text_width = font:getWidth(wrapped_text)
        if text_width > content_w - (20 * ui_scale) then
            -- Simple word wrapping for long lines
            local max_chars = math.floor((content_w - (20 * ui_scale)) / font:getWidth("W"))
            wrapped_text = wrapped_text:sub(1, max_chars) .. "..."
        end
        
        love.graphics.print(wrapped_text, content_x + (10 * ui_scale), line_y)
    end
    
    -- Remove scissor
    love.graphics.setScissor()
    
    -- Scrollbar if needed
    if #debug_messages > visible_lines then
        local scrollbar_x = panel.x + panel.width - (12 * ui_scale)
        local scrollbar_y = content_y
        local scrollbar_h = content_h
        local scrollbar_w = 6 * ui_scale
        
        -- Scrollbar track
        love.graphics.setColor(0.2, 0.2, 0.3, 0.5)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y, scrollbar_w, scrollbar_h, 3 * ui_scale)
        
        -- Scrollbar thumb
        local thumb_ratio = visible_lines / #debug_messages
        local thumb_height = scrollbar_h * thumb_ratio
        local thumb_offset = (scroll_offset / (#debug_messages - visible_lines)) * (scrollbar_h - thumb_height)
        
        love.graphics.setColor(theme.primary[1], theme.primary[2], theme.primary[3], 0.8)
        love.graphics.rectangle("fill", scrollbar_x, scrollbar_y + thumb_offset, scrollbar_w, thumb_height, 3 * ui_scale)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

-- Clear all messages
function M.clear()
    debug_messages = {}
    scroll_offset = 0
end

return M
