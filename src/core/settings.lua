
local M = {}
function M.build()
  return {
    WORLD_SIZE = 4500,
    STAR_COUNT_BG = 800,
    STAR_COUNT_FG = 400,
    MAX_ENEMIES = 32,
    ENEMY_RESPAWN_TIME = 2.0,
    CAMERA_SMOOTH = 8,
    ZOOM = 1.0,
    UI_SCALE = 1.0,
    AUTOSAVE_INTERVAL = 60,
  }
end
return M
