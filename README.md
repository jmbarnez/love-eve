
# DarkOrbit-Style Single Player (Refactored, LÖVE 11.x)

Single-player, credit/XP-only arcade space shooter inspired by DarkOrbit — **no premium currencies**.

## Run
1. Install [LÖVE](https://love2d.org/).
2. Download and unzip this project.
3. Drag the folder onto the LÖVE app (or run `love .` inside the folder).

## Controls
- **W/A/S/D**: Thrust
- **Shift**: Afterburner (burns energy)
- **LMB**: Fire primary blaster
- **RMB**: Set autopilot destination
- **F**: Toggle autopilot follow mouse
- **Space**: Quick-stop (kill velocity)
- **E**: Dock/Undock at station, open upgrades
- **Tab**: Expand/Collapse minimap
- **H**: Toggle help overlay
- **F5**: Save  |  **F9**: Load
- **Esc**: Pause

## What changed in this refactor?
- Code split into small, reusable modules under `src/` and `assets/`.
- A **starter ship model** lives in `assets/ships/starter.lua` and is rendered vectorially.
- **Enemy behavior**: starter enemies **do not aggro** from long distances anymore — they only become aggressive **after you attack them** (they drift idly otherwise).
- Modular systems for player, enemies, bullets, loot, HUD, world rendering, docking UI, camera, saving.

## Structure
```
.
├── main.lua
├── README.md
├── assets
│   └── ships
│       └── starter.lua
└── src
    ├── core
    │   ├── camera.lua
    │   ├── ctx.lua
    │   ├── save.lua
    │   ├── settings.lua
    │   └── util.lua
    ├── entities
    │   ├── bullet.lua
    │   ├── enemy.lua
    │   ├── loot.lua
    │   └── player.lua
    ├── render
    │   ├── hud.lua
    │   └── world.lua
    └── ui
        └── dock.lua
```

## Notes
- Save file: `save.lua` in LÖVE's save directory.
- To change the ship, replace `assets/ships/starter.lua` with another module exposing `draw(x,y,rot,scale)`.

### Assets Organization
- `assets/ships/` — ship drawing modules (vector-based)
- `assets/effects/` — reusable visual effects (e.g., engine thrusters)
- `assets/weapons/` — projectile visuals
