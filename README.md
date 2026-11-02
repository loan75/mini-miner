# Mini-mineur

A small 2D mining game made with Godot 4, started as a first complete project and now used as a playground for the digging prototype of a bigger game.
Dig through the mine and collect as many points as you can before your energy or the timer runs out.

**Play it in your browser:** https://denkitsune.itch.io/mining

## How to play

| Action | Keyboard | Touchscreen |
| --- | --- | --- |
| Move | Left / Right arrows | Left / Right buttons |
| Mine | Hold an arrow (Left, Right or Down) against a block | Hold a direction button against a block |
| Jump | Space | Jump button |
| Start / Retry | Space | Touch the screen |

## Rules

- Every pickaxe hit costs 2 energy. You start with 200 energy.
- Each run digs through a new mine, generated from a random seed.
- Blocks need several hits to break, depending on their hardness. An ore adds to the hardness of the block around it:

| Cell | Hits to break | Points |
| --- | --- | --- |
| Dirt | 1 | 1 |
| Gold in dirt | 3 | 10 |

- The sides and the bottom of the mine cannot be dug.

- Cracks show how damaged a block is. Damage is kept if you leave a block and come back.
- The game ends when your energy reaches 0 or when the 60-second timer runs out.
- Try to beat your best score.

## Features

- Procedurally generated mines (FastNoiseLite caves, blocks and ores chosen by depth), with a loading screen
- Hit-based mining on a tile grid, with auto-tiling of the remaining terrain
- Data-driven blocks, ores and mines: hardness, points, sounds, particle colours and spawn rules defined in resources, not in code
- Per-tile damage with 4 crack stages
- Mining animation synced to the dig speed
- Camera that follows the miner, with limits computed from the map
- Energy, score and timer HUD
- Title screen and game over screen with instant retry
- Keyboard and touchscreen controls, detected automatically
- Pixel-art rendering at 480 × 270, scaled ×3
- Sound effects, particles and background music

## Run the project locally

1. Install [Godot 4.7](https://godotengine.org/download) or later (standard version, GDScript).
2. Install [Git LFS](https://git-lfs.com): images and sounds are stored with it.
3. Clone the repository:
   ```bash
   git lfs install
   git clone https://github.com/loan75/mini-mineur.git
   ```
   If Godot reports "failed loading resource" on the assets, the LFS files were not downloaded: run `git lfs pull` in the project folder.
4. Open Godot, click **Import**, select the `project.godot` file, then press **F5** to play.

To build the web version: **Project > Export > Web**. The export goes to `exports/`, which is ignored by Git.

## Testing a mine

- Each run prints its seed in the Output panel (`Mine seed: ...`). To replay a mine, set that value in the `Mine Seed` property of the `MineLevel` node. 0 means a random seed.
- In debug builds, press **R** to regenerate the mine with a new seed.
- To change a mine, edit its `.tres` in `Resources/Mines/`: size, noise, cave threshold, block and ore spawns.

## Adding a new block type

1. In the FileSystem dock, right-click `Resources/Blocks/` > **New Resource** > **BlockData**.
2. Set its name, hardness (hits needed with a power-1 pickaxe), points, hit sound, particle gradient and `terrain` (its terrain index in the Mine tileset's terrain set).
3. In the Mine TileSet, assign the resource to the `block` custom data of every tile of that terrain.
4. In a mine's `.tres`, add a **BlockSpawn** to `blocks` with a weight and a depth range.

## Adding a new ore

1. Right-click `Resources/Ores/` > **New Resource** > **OreData**. Set `tile` to its atlas coordinates on the Ore layer, its extra hardness, points, hit sound and particle gradient.
2. In the Ore TileSet, assign the resource to the `ore` custom data of that tile.
3. In a mine's `.tres`, add an **OreSpawn** to `ores` with a chance per cell, a depth range and, optionally, the blocks it can appear in. Put the rarest ores first in the list.

## Project structure

```
Assets/          Sprites, tilesets, crack overlay, music and sound effects
Resources/       Data only: resource scripts and their .tres files
  Blocks/        BlockData (ground types) and BlockSpawn (spawn rules)
  Enemies/       EnemyData (not used yet)
  Items/         ItemData (not used yet)
  Mines/         MineData: size, noise and spawn rules of each mine
  Ores/          OreData (gold...) and OreSpawn (spawn rules)
Scenes/
  Effects/       Dig particles
  HUD/           Display only: energy, score, timer, game over and touch controls
  LoadingScreen/ Progress bar shown while a mine is generated
  MainMenu/      Title screen with the controls
  Mine/          Level: game rules and wiring; MineGenerator and MineLayout (generation)
  Player/        The miner: input, movement and dig state machines, animations and sounds
  Terrain/       Diggable layers: drawing a layout, block and ore lookup, damage, cracks, particles
```

The scenes follow "call down, signal up": the level calls methods on its children and listens to their signals, and the terrain, the miner and the HUD never reach each other directly.

## Changelog

- **0.5.1**: camera smoothing, tile data fixes, renames
- **0.5**: block types with hardness and points, per-tile damage with cracks, camera following the miner, animation synced to dig speed, one hit sound per block type
- **0.1 to 0.4**: first release and fixes

## Credits

- Game design and code: Loan Harrouin (Denkitsune)
- Made with the [Godot Engine](https://godotengine.org)
