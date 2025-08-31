local M = {}

-- Service locator for dependency injection
local services = {}

-- Register a service
function M.register(name, service)
  services[name] = service
end

-- Get a service
function M.get(name)
  return services[name]
end

-- Unregister a service
function M.unregister(name)
  services[name] = nil
end

-- Check if service exists
function M.has(name)
  return services[name] ~= nil
end

-- Clear all services
function M.clear()
  services = {}
end

-- Get all registered services
function M.getAll()
  local result = {}
  for name, service in pairs(services) do
    result[name] = service
  end
  return result
end

return M
