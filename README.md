# Skytrail Expedition

A light obby / adventure game for Roblox. Explore floating sky islands, clear nature-themed obstacles, hit checkpoints, collect hidden **Relics**, and reach the tower at the top.

- **Genre:** Obby / Adventure
- **Platforms:** Mobile first, then desktop
- **Price:** Free to play
- **Status:** 🚧 Pre-alpha. Design is done, and the first playable greybox is next.

## MVP scope

- A small hub and one world, **Sky Ruins**, with about 20 stages
- Four obstacle types: jump platforms, kill bricks, moving platforms, and collapsing paths
- Checkpoints with respawn, a finish line, and a Coins reward
- Hidden Relics to collect
- Saved progress (checkpoint, Coins, Relics, cosmetics)
- Optional Skip Stage, payable with Coins or Robux. Every stage can be finished without paying.

## Tech stack

| | |
|---|---|
| Language | [Luau](https://luau.org) (strict mode) |
| Sync | [Rojo](https://rojo.space) 7.7.1, so code lives on disk and in git |
| Toolchain | [Rokit](https://github.com/rojo-rbx/rokit): rojo, luau-lsp, selene, StyLua, wally |
| Save data | [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) |

Code lives in this repo. The map (islands, stages, 3D models) is built in Roblox Studio and saved to Roblox, not to git. Code finds map parts through CollectionService tags.

## Project structure

```text
src/
  server/   → ServerScriptService.Server   game rules, rewards, saving, purchases
  client/   → StarterPlayerScripts.Client  UI, input, effects
  shared/   → ReplicatedStorage.Shared     config, tag names, types
default.project.json                       Rojo project
rokit.toml                                 pinned tool versions
```

## Getting started

Requirements: macOS, Windows, or Linux with [Roblox Studio](https://create.roblox.com) and [Rokit](https://github.com/rojo-rbx/rokit).

```bash
rokit install          # installs the pinned tools
rojo serve             # starts the sync server
```

Then, in Roblox Studio, install the Rojo plugin, open a place, and click **Connect**.

### Checks

```bash
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform roblox --definitions globalTypes.d.luau --sourcemap sourcemap.json src
selene src
stylua --check src
```

`globalTypes.d.luau` (Roblox type definitions) and `roblox.yml` (selene's Roblox standard library) are not committed:

```bash
curl -sSfL -o globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
selene generate-roblox-std
```

## License

© [fatihaljabar](https://github.com/fatihaljabar). All rights reserved. The source is public to read, but it is not licensed for reuse.
