local M = {}

-- Event system for decoupling modules
local listeners = {}

-- Register a listener for an event
function M.on(event, callback)
  if not listeners[event] then
    listeners[event] = {}
  end
  table.insert(listeners[event], callback)
end

-- Remove a listener for an event
function M.off(event, callback)
  if listeners[event] then
    for i, cb in ipairs(listeners[event]) do
      if cb == callback then
        table.remove(listeners[event], i)
        break
      end
    end
  end
end

-- Emit an event with data
function M.emit(event, data)
  if listeners[event] then
    for _, callback in ipairs(listeners[event]) do
      callback(data)
    end
  end
end

-- Clear all listeners for an event
function M.clear(event)
  listeners[event] = nil
end

-- Clear all listeners
function M.clearAll()
  listeners = {}
end

return M
