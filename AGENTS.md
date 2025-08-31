# Repository Guidelines

This repository contains a single‑player space game built with LÖVE 11.x and Lua. Follow these guidelines to keep changes consistent and easy to review.

## Project Structure & Module Organization

- `main.lua`: Game entry; initializes state, systems, and UI.
- `src/core`: Engine primitives (e.g., `state.lua`, `settings.lua`, `camera.lua`, `persistence/save.lua`).
- `src/entities`: Gameplay actors and loot (`player.lua`, `enemy.lua`, `loot.lua`, `loot_box.lua`).
- `src/systems`: Update logic (e.g., `projectiles.lua`, `shield.lua`, `player/inventory.lua`).
- `src/render`: Rendering (`world.lua`).
- `src/ui`: Heads‑up display and dock windows (`simple_ui.lua`, `dock_window.lua`).
- `src/content`: Data/config by type (`ships/`, `credit.lua`).
- `src/models`: Registries and type definitions (`items/registry.lua`, `projectiles/types/`).

## Build, Test, and Development Commands

- Run locally: `love .`
- With console (when supported): `love . --console`
- Package (optional): `zip -9 -r game.love . -x ".git*" "*.md"` then `love game.love`

## Coding Style & Naming Conventions

- Indentation: 2 spaces; UTF‑8; LF line endings.
- Files/modules: snake_case paths under `src`, return a table from modules.
- Locals/fields: `lower_snake_case`; temporary variables are descriptive, not single letters.
- Constants/config: UPPER_SNAKE (e.g., keys in `settings.lua`).
- Avoid globals; read/write shared state via `src/core/state.lua`.
- Keep modules focused; prefer pure helpers in `src/core/util.lua`.

## Testing Guidelines

- No formal unit tests yet. Validate features via in‑game playtesting.
- For logic‑heavy additions, consider adding `busted` specs (if introduced later). Suggested naming: `spec/<module>_spec.lua`.
- Include reproduction steps and expected results in PR descriptions.

## Commit & Pull Request Guidelines

- Commits: concise, present tense, describe intent (e.g., "projectiles: fix lifetime clamp"). Use additional paragraphs for rationale when helpful.
- PRs: clear description, linked issues, steps to verify, and before/after notes (screenshots or short GIFs appreciated for UI/gameplay changes).
- Scope PRs narrowly; update docs if paths/APIs change.

## Security & Configuration Tips

- Saves are handled via `love.filesystem` (`persistence/save.lua`); avoid writing outside it.
- Do not load untrusted code or assets at runtime. Keep data‑driven additions under `src/content/`.
