-- Simple module loader helpers
local M = {}
local function norm(p) return (p:gsub("/", ".")) end
function M.requireAll(path)
  local items = {}
  local fsPath = path:gsub("%.", "/")
  if love and love.filesystem and love.filesystem.getDirectoryItems then
    for _, file in ipairs(love.filesystem.getDirectoryItems(fsPath)) do
      if file:match("%.lua$") then
        local mod = require(norm(path).."."..file:sub(1, -5))
        table.insert(items, mod)
      end
    end
  end
  return items
end
return M
