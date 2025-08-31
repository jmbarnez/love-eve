
local config = require("src.core.config")

local M = {}

function M.build()
  -- Return game configuration
  return config.game
end

return M
