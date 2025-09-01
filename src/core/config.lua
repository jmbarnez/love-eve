local M = {}

-- Centralized configuration for all balance values
M.game = {
  WORLD_SIZE = 4500,
  STAR_COUNT_BG = 800,
  STAR_COUNT_FG = 400,
  MAX_ENEMIES = 25,
  ENEMY_RESPAWN_TIME = 6.0,
  CAMERA_SMOOTH = 8,
  ZOOM = 1.2,
  UI_SCALE = 1.0,
  AUTOSAVE_INTERVAL = 60,

  -- Window settings
  WINDOW_FULLSCREEN = true,
  WINDOW_RESIZABLE = true,
  WINDOW_VSYNC = true,

  -- Game timing
  MAX_DT = 1/30, -- Maximum delta time to prevent large jumps

  -- Zoom controls
  ZOOM_STEP = 1.2,
  ZOOM_MIN = 0.5,
  ZOOM_MAX = 2.0,
}

M.player = {
  radius = 14,
  accel = 80,
  maxSpeed = 160,
  friction = 1.0,
  energy = 100,
  maxEnergy = 100,
  energyRegen = 14,
  hp = 100,
  maxHP = 100,
  shield = 120,
  maxShield = 120,
  shieldRegen = 10,
  shieldCDMax = 2.0,
  damage = 12,
  fireCooldownMax = 2.0,
  spread = 0.06,
  energyCostPerShot = 4,
  energyCostMovement = 6,
  regenMultiplierDocked = 2.0, -- Multiplier for regen when docked
}

M.enemy = {
  radius = 12,
  shieldRegen = 6,
  shieldCDMax = 2.4,
  minDistanceBetween = 200,
  spawnDistanceMin = 900,
  spawnDistanceMax = 1500,
  respawnTimes = { -- Configurable respawn times per enemy type (seconds)
    standard = 30.0,
    aggressive = 35.0,
    sniper = 45.0,
    bruiser = 50.0
  },
  presets = {
    [1] = {
      hp = 40,
      speed = 240,
      damage = 10,
      fireCooldownMax = 1.11,
      range = 520,
      xpReward = 20,
      creditReward = 30,
      tier = 1
    },
    [2] = {
      hp = 70,
      speed = 280,
      damage = 12,
      fireCooldownMax = 0.83,
      range = 640,
      xpReward = 30,
      creditReward = 45,
      tier = 2
    },
    [3] = {
      hp = 110,
      speed = 320,
      damage = 16,
      fireCooldownMax = 0.625,
      range = 700,
      xpReward = 40,
      creditReward = 65,
      tier = 3
    },
    [4] = {
      hp = 160,
      speed = 360,
      damage = 20,
      fireCooldownMax = 0.5,
      range = 760,
      xpReward = 55,
      creditReward = 90,
      tier = 4
    },
  }
}

M.projectiles = {
  shieldRadiusOffset = 8,
  bulletShieldDamageMultiplier = 0.5,
  lockOnRange = 400,
  lockOnDelay = 0.3,
  spawnOffset = 8,
  homingStrength = 5.0,
  rocketLockOnDelay = 0.3,
}

M.ui = {
  barWidth = 30,
  barHeight = 5,
  barOffsetY = 12,
  interactionRadiusOffset = 12,
  moveMarkerDuration = 1.25,
  attackIndicatorRadiusOffset = 6,
}

M.world = {
  stationRadius = 280,
  coreRadius = 120,
  dockingRadius = 320,
  waypointRadius = 12,
  targetIndicatorRadiusOffset = 10,
}

M.gameplay = {
  -- Player death and respawn
  deathParticlesCount = 40,
  deathParticlesVx = {-120, 120},
  deathParticlesVy = {-120, 120},
  deathParticlesLife = {0.6, 1.2},
  deathRecoveryMultiplier = 0.6,
  deathMinHP = 30,
  deathMinShield = 40,
  cameraShakeOnDeath = 1.0,

  -- Player spawn/respawn
  spawnOffsetFromStation = 150,
  projectileVelocityMultiplier = 0.3,

  -- Main game constants
  dampingBrakeStrength = 0.2,
  continueBrakeStrength = 0.1,
  continueVelocityThreshold = 0.1,
}

return M
