# Brainrot Collector — roblox-brainrot-01

A 3D Roblox collector / tycoon game for make.fun's
"Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01),
entry by @bangre / bangre-ctrl.

## How to play

- Wild brainrots wander the field (Tung Tung Tung Sahur, Tralalero
  Tralala, Chimpanzini Bananini, Bombardiro Crocodilo, Lirili Larila,
  Cappuccino Assassino, Brr Brr Patapim, La Vaca Saturno Saturnita).
  Click one to collect it for coins.
- Gold coins spawn around the map; touch one for +10 coins.
- Spend coins in the shop (right side of the screen) to buy a brainrot
  follower. Followers walk behind you and earn coins every second.
- The player with the most brainrots collected when the 5-minute
  round timer ends is announced as the round winner.
- Coins, brainrots collected and income are on the Roblox leaderboard.

## How it is built

- `src/shared/BrainrotData.luau` — the 8 brainrots: rarity, cost,
  income, reward, colours, size.
- `src/server/init.server.luau` — builds the whole 3D world in code
  (ground, roads, plaza, spawn, shop stall, trees, lamps, fences,
  welcome sign), spawns and moves wild brainrots, coins, followers,
  income, the round timer and the leaderboard. No terrain or model
  has to be built by hand in Studio.
- `src/client/Game.client.luau` — top bar, shop panel, live
  leaderboard, notifications and start screen.
- `main.ts` (Node 22, standard library only) hands the game in: it
  copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to
  `/output` and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts` (unchanged).

## Build

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

## Publish (in Roblox Studio, on Windows/Mac)

1. Open this project in Roblox Studio (Rojo plugin, or open
   `game.rbxl`).
2. Play-test, take 3 screenshots, replace `screenshots/`.
3. Publish as a Public experience, upload an icon and a thumbnail
   (one screenshot must be the game's first thumbnail), put the
   play code in the experience description.
4. Fill in `PLAY.json` with the real place URL, `place_id` and
   `universe_id`.
