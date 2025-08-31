
local M = {}
function M.build()
  -- Simple fixed UI scale to prevent performance issues
  return {
    WORLD_SIZE = 4500,
    STAR_COUNT_BG = 800,
    STAR_COUNT_FG = 400,
    MAX_ENEMIES = 8,  -- Reduced from 32 for better balance
    ENEMY_RESPAWN_TIME = 6.0,  -- Increased from 2.0 for slower spawning
    CAMERA_SMOOTH = 8,
    ZOOM = 1.0,
    UI_SCALE = 1.0,  -- Fixed scale for now
    AUTOSAVE_INTERVAL = 60,
  }
end
return M
