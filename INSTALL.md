# Installation

## How to Install

1. Navigate to your Dota 2 game files directory:
   ```
   Steam/steamapps/common/dota 2 beta/game/dota/addons/npx_2019/
   ```

2. **Back up** the existing `npx_2019` folder before making changes.

3. Copy the contents of this repository into the `npx_2019` folder, overwriting existing files.

4. Launch Dota 2 and load any New Player Experience scenario from the Learn tab.

## File Structure

```
npx_2019/
├── resource/          # Localization files
├── scripts/
│   ├── npc/           # NPC definitions and precache
│   ├── scripts/       # Compiled scripts
│   ├── shops/         # Shop configurations
│   ├── talker/        # Voice line configs
│   └── vscripts/      # Lua scenario scripts (main fixes here)
│       ├── scenarios/  # Individual scenario files
│       ├── tasks/      # Task system files
│       └── ai/         # Bot AI scripts
└── README.md          # Changelog
```

## What Was Changed

The primary changes are in `scripts/vscripts/scenarios/` and `scripts/vscripts/tasks/`. See the [README](README.md) for a full breakdown of fixes.
